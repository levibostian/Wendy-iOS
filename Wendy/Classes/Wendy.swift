import Foundation

public class Wendy {
    public static var shared: Wendy = Wendy()
    
    private var initializedData: InitializedData? = nil // populated after setup() called.
    
    internal var taskRunner: WendyTaskRunner? {
        initializedData?.taskRunner
    }

    private init() {}

    public class func setup(taskRunner: WendyTaskRunner, debug: Bool = false) {
        Wendy.shared.initializedData = InitializedData(taskRunner: taskRunner)
        WendyConfig.debug = debug
    }

    /**
     Convenient function to call in your AppDelegate's `application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)` function for running a background fetch.

     It will return back a `WendyUIBackgroundFetchResult`. You can take the `WendyUIBackgroundFetchResult`, pull out the `backgroundFetchResult` processed for you, and return that if you wish to `completionHandler`. Or return your own `UIBakgroundFetchResult` processed yourself from your app or from the Wendy `taskRunnerResult` in the `WendyUIBackgroundFetchResult`.
     */
    public final func performBackgroundFetch() -> WendyUIBackgroundFetchResult {
        if !WendyConfig.automaticallyRunTasks {
            LogUtil.d("Wendy configured to *not* automatically run tasks. Skipping execution of background fetch job.")
            return WendyUIBackgroundFetchResult(taskRunnerResult: PendingTasksRunnerResult.new(), backgroundFetchResult: .noData)
        }

        LogUtil.d("backgroundFetchRunTasks() called. Wendy configured to automatically run tasks. Running the background fetch job.")
        let runAllTasksResult = PendingTasksRunner.Scheduler.shared.scheduleRunAllTasksWait(filter: nil)

        return WendyUIBackgroundFetchResult(taskRunnerResult: runAllTasksResult, backgroundFetchResult: runAllTasksResult.backgroundFetchResult)
    }
    
    public final func addTask(tag: String, dataId: String?, groupId: String? = nil) -> Double {
        let pendingTaskToAdd = PendingTask.nonPersisted(tag: tag, dataId: dataId, groupId: groupId)

        // We enforce a best practice here.
        if let similarTask = PendingTasksManager.shared.getRandomTaskForTag(pendingTaskToAdd.tag) {
            if similarTask.groupId == nil && pendingTaskToAdd.groupId != nil {
                Fatal.preconditionFailure("Cannot add task: \(pendingTaskToAdd.describe()). All subclasses of a PendingTask must either **all** have a groupId or **none** of them have a groupId. Other \(pendingTaskToAdd.tag)'s you have previously added does not have a groupId. The task you are trying to add does have a groupId.")
            }
            if similarTask.groupId != nil && pendingTaskToAdd.groupId == nil {
                Fatal.preconditionFailure("Cannot add task: \(pendingTaskToAdd.describe()). All subclasses of a PendingTask must either **all** have a groupId or **none** of them have a groupId. Other \(pendingTaskToAdd.tag)'s you have previously added does have a groupId. The task you are trying to add does not have a groupId.")
            }
        }

        if let existingPendingTasks = PendingTasksManager.shared.getExistingTasks(pendingTaskToAdd), !existingPendingTasks.isEmpty {
            let sampleExistingPendingTask = existingPendingTasks.last!

            if let currentlyRunningTask = PendingTasksRunner.shared.currentlyRunningTask, currentlyRunningTask.equals(sampleExistingPendingTask) {
                PendingTasksUtil.rerunCurrentlyRunningPendingTask = true
                return sampleExistingPendingTask.id
            }
            // If a PendingTask belongs to a group, but is *not* the last item in the group, we want to insert it into CoreData. Let is pass through below to add itself.
            if let groupId = pendingTaskToAdd.groupId {
                if let lastPendingTaskInGroup = PendingTasksManager.shared.getLastPendingTaskInGroup(groupId), lastPendingTaskInGroup.pendingTask.equals(pendingTaskToAdd) {
                    return lastPendingTaskInGroup.id
                }
            } else {
                return sampleExistingPendingTask.id
            }
        }

        let addedPendingTask: PendingTask = PendingTasksManager.shared.insertPendingTask(pendingTaskToAdd)

        WendyConfig.logNewTaskAdded(pendingTaskToAdd)

        try runTaskAutomaticallyIfAbleTo(addedPendingTask)

        return addedPendingTask.taskId!
    }

    /**
     * Note: This function is for internal use only. There are no checks to make sure that it exists and stuff. It's assumed you know what you're doing.

     This function exists for this scenario:
     1. Only run depending on WendyConfig.automaticallyRunTasks.
     2. If task is *able* to run.

     Those make this function unique compared to `runTask()` because that function ignores WendyConfig.automaticallyRunTasks *and* if the task.manuallyRun property is set or not.
     */
    internal func runTaskAutomaticallyIfAbleTo(_ task: PendingTask) -> Bool {
        if !WendyConfig.automaticallyRunTasks {
            LogUtil.d("Wendy configured to not automatically run tasks. Skipping execution of newly added task: \(task.describe())")
            return false
        }
        if try !isTaskAbleToManuallyRun(task.taskId!) {
            LogUtil.d("Task is not able to manually run. Skipping execution of newly added task: \(task.describe())")
            return false
        }

        LogUtil.d("Wendy is configured to automatically run tasks. Wendy will now attempt to run newly added task: \(task.describe())")
        runTask(task.taskId!, onComplete: nil)

        return true
    }

    public final func runTask(_ taskId: Double, onComplete: ((TaskRunResult) -> Void)?) {
        guard let pendingTask: PendingTask = PendingTasksManager.shared.getPendingTaskTaskById(taskId) else {
            onComplete?(TaskRunResult.cancelled)
            return
        }

        if !isTaskAbleToManuallyRun(taskId) {
            Fatal.preconditionFailure("Task is not able to manually run. Task: \(pendingTask.describe())")
        }

        PendingTasksRunner.Scheduler.shared.scheduleRunPendingTask(taskId) { result in
            onComplete?(result)
        }
    }

    public final func isTaskAbleToManuallyRun(_ taskId: Double) -> Bool {
        guard let pendingTask: PendingTask = PendingTasksManager.shared.getPendingTaskTaskById(taskId) else {
            return false
        }

        if pendingTask.groupId == nil {
            return true
        }

        return PendingTasksManager.shared.isTaskFirstTaskOfGroup(taskId)
    }

    /**
     * Checks to make sure that a [PendingTask] does exist in the database, else throw an exception.
     *
     * Why throw an exception? I used to simply ignore your request if you called a function such as [recordError] if you gave a taskId parameter for a task that did not exist in the database. But I decided to remove that because [PendingTask] should always be found in the database unless one of the following happens:
     *
     * 1. You did not add the [PendingTask] to the database in the first place which you should get an exception thrown on you then to make sure you fix that.
     * 2. The [PendingTask] previously existed, but the task ran successfully and the task runner deleted. In that case, you *should* not be doing actions such as trying to record errors then, right? You should have returns [PendingTaskResult.FAILED] instead which will not delete your task.
     *
     * You do not need to use this function. But you should use it if there is a scenario when a [PendingTask] could be deleted and your code tries to perform an action on it. Race conditions are real and we do keep them in mind. But if your code *should* be following best practices, then we should throw exceptions instead to get you to fix your code.
     */
    /*
     Update: Now that tasks can be cancelled, the following scenario is possible:
     1. Multiple tasks in queue to run.
     2. All tasks cancelled.
     3. Run all tasks. As tasks, one-by-one, get cancelled and tell listeners via async update to the main thread, there is a race condition. A listener could get notified of an update, requery Wendy for a list of all pending tasks, receive tasks A, B, C at that time but then as the main thread is populating the table, it could encounter A gets deleted on background thread resulting in this function calling fatal.
     You can try this on yourself. Add many tasks to the queue with automatically running them off. Clear all tasks. Then run them all. Chances are high of a fatal crash of ID not existing.
     */

//    internal func assertPendingTaskExists(_ taskId: Double) -> PendingTask {
//        let pendingTask: PendingTask? = PendingTasksManager.shared.getPendingTaskTaskById(taskId)
//        if pendingTask == nil {
//            Fatal.preconditionFailure("Task with id: \(taskId) does not exist.")
//        }
//        return pendingTask!
//    }

    public final func runTasks(filter: RunAllTasksFilter? = nil, onComplete: ((PendingTasksRunnerResult) -> Void)?) {
        PendingTasksRunner.Scheduler.shared.scheduleRunAllTasks(filter: filter) { result in
            onComplete?(result)
        }
    }

    public final func getAllTasks() -> [PendingTask] {
        return PendingTasksManager.shared.getAllTasks()
    }

    /**
     Sets pending tasks that are in the queue to run as cancelled. Tasks are all still queued, but will be deleted and skipped to run when the task runner encounters them.

     Note: If a task is currently running when clear() is called, that running task will be finish executing but will not run again in the future as it has been cancelled.
     */
    public final func clear() {
        /// It's not possible to stop a dispatch queue of tasks so there is no way to stop the currently running task runner.
        /// This solution of using UserDefaults to set a threshold solves that problem while also leaving Wendy untouched to continue running as usual. If we deleted all data, as Android's Wendy does, we would have potential issues with tasks that are still in the queue but core data and userdefaults being deleted causing potential crashes and IDs being misaligned.
        PendingTasksUtil.setValidPendingTasksIdThreshold()
        LogUtil.d("Wendy tasks set as cancelled. Currently scheduled Wendy tasks will all skip running.")
        // Run all tasks (including manually run tasks) as they are all cancelled so it allows them all to be cleared fro the queue now and listeners can get notified.
        getAllTasks().forEach { task in
            self.runTask(task.taskId!, onComplete: nil)
        }
    }
    
    struct InitializedData {
        let taskRunner: WendyTaskRunner
    }
}
