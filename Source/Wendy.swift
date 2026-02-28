import Foundation

public final class Wendy: Sendable, Singleton {
    public static let shared: Wendy = .init()

    var taskRunner: WendyTaskRunner? {
        dataStore.getDataSnapshot().taskRunner
    }

    private var pendingTasksRunner: PendingTasksRunner { .shared }

    private init() {}

    public func reset() {}

    /// Sets up Wendy with the provided task runner and configuration options.
    /// - Parameters:
    ///   - taskRunner: The task runner to use for executing tasks.
    ///   - debug: Enable debug logging. Defaults to false.
    ///   - semaphoreValue: The maximum number of concurrent tasks allowed. Defaults to 1.
    public static func setup(taskRunner: WendyTaskRunner, debug: Bool = false, semaphoreValue: Int = 1) {
        WendyConfig.semaphoreValue = semaphoreValue
        DataStore.shared.updateDataBlock { $0.taskRunner = taskRunner }
        WendyConfig.debug = debug
    }

    /**
     Add a new task to Wendy to run later.

     Wendy maintains a FIFO queue data structure of tasks. This newly added task will be added to the queue.

     Wendy guarantees that tasks are saved when added. To do this, Wendy writes the task to persistant device memory synchronously on the calling thread.
     */
    @discardableResult
    public func addTask(tag: String, data: (some Codable)?, groupId: String? = nil) -> Double {
        let addedTask = DIGraph.shared.pendingTasksManager.add(tag: tag, data: data, groupId: groupId)

        LogUtil.logNewTaskAdded(addedTask)

        runTaskAutomaticallyIfAbleTo(addedTask)

        return addedTask.taskId!
    }

    @discardableResult
    public func addTask<Tag: RawRepresentable>(tag: Tag, data: (some Codable)?, groupId: String? = nil) -> Double where Tag.RawValue == String {
        addTask(tag: tag.rawValue, data: data, groupId: groupId)
    }

    /// Returns list of task IDs that contain *all* of the key/value pairs passed in the query.
    public func findTasks(containingAll query: [String: any Sendable & Hashable]) async -> [Double] {
        // Creating a Task because the getAllTasks() is currently not async. Creating a new Task is to try and make this more performant in case this function called on main thread.
        await Task {
            let allTasks = DIGraph.shared.pendingTasksManager.getAllTasks()

            return allTasks.filter { task in
                let taskData = task.dataAsDictionary

                // For every element in query, the task must contain everything in it.
                return query.allSatisfy { key, value in
                    guard taskData.keys.contains(key) else { return false }

                    let queryValue = AnyHashable(value)
                    let taskValue = taskData[key]

                    return queryValue == taskValue
                }
            }.map { $0.taskId! }
        }.value
    }

    /// Returns list of task IDs that contain *at least one* of the key/value pairs passed in the query.
    public func findTasks(containingAny query: [String: any Sendable & Hashable]) async -> [Double] {
        // Creating a Task because the getAllTasks() is currently not async. Creating a new Task is to try and make this more performant in case this function called on main thread.
        await Task {
            let allTasks = DIGraph.shared.pendingTasksManager.getAllTasks()

            return allTasks.filter { task in
                let taskData = task.dataAsDictionary

                // For every element in query, the task must contain everything in it.
                let didFindAMatch = query.first(where: { key, value in
                    guard taskData.keys.contains(key) else { return false }

                    let queryValue = AnyHashable(value)
                    let taskValue = taskData[key]

                    return queryValue == taskValue
                }) != nil

                return didFindAMatch
            }.map { $0.taskId! }
        }.value
    }

    /**
     * Note: This function is for internal use only. There are no checks to make sure that it exists and stuff. It's assumed you know what you're doing.

     This function exists for this scenario:
     1. Only run depending on WendyConfig.automaticallyRunTasks.
     2. If task is *able* to run.

     Those make this function unique compared to `runTask()` because that function ignores WendyConfig.automaticallyRunTasks *and* if the task.manuallyRun property is set or not.
     */
    @discardableResult
    func runTaskAutomaticallyIfAbleTo(_ task: PendingTask) -> Bool {
        if !WendyConfig.automaticallyRunTasks {
            LogUtil.d("Wendy configured to not automatically run tasks. Skipping execution of newly added task: \(task.describe())")
            return false
        }

        LogUtil.d("Wendy is configured to automatically run tasks. Wendy will now attempt to run newly added task: \(task.describe())")
        Task {
            _ = await runTask(task.taskId!)
        }

        return true
    }

    /**
     Given a Wendy task id (the return value of `addTask`), run the task.

     Wendy runs only 1 task at a time. If a task is already running when this function is called, Wendy will wait for the other task to finish, run this given task, then return.

     The codebase is trying to move away from task ids. It's suggested to use `runTasks(filter:)` instead.
     */
    public func runTask(_ taskId: Double) async -> TaskRunResult {
        guard let _ = DIGraph.shared.pendingTasksManager.getTaskByTaskId(taskId) else {
            return .cancelled
        }

        let result = await pendingTasksRunner.runTask(taskId: taskId)

        return result
    }

    /**
     Runs all tasks that have been added to Wendy.

     Wendy maintains a FIFO queue of added tasks. When this function is called, Wendy will run each task in the queue, 1 task at a time.

     To be more efficient, if Wendy is already running all tasks, this function call will return when that existing run is complete.
     */
    @discardableResult
    public func runTasks(filter: RunAllTasksFilter? = nil) async -> PendingTasksRunnerResult {
        let result = await pendingTasksRunner.runAllTasks(filter: filter)

        return result
    }

    public final func getAllTasks() -> [PendingTask] {
        DIGraph.shared.pendingTasksManager.getAllTasks()
    }

    /**
     Sets pending tasks that are in the queue to run as cancelled. Tasks are all still queued, but will be deleted and skipped to run when the task runner encounters them.

     Note: If a task is currently running when clear() is called, that running task will be finish executing but will not run again in the future as it has been cancelled.
     */
    public final func clear() async {
        /// It's not possible to stop a dispatch queue of tasks so there is no way to stop the currently running task runner.
        /// This solution of using UserDefaults to set a threshold solves that problem while also leaving Wendy untouched to continue running as usual. If we deleted all data, as Android's Wendy does, we would have potential issues with tasks that are still in the queue but core data and userdefaults being deleted causing potential crashes and IDs being misaligned.
        PendingTasksUtil.setValidPendingTasksIdThreshold()
        LogUtil.d("Wendy tasks set as cancelled. Currently scheduled Wendy tasks will all skip running.")
        // Run all tasks (including manually run tasks) as they are all cancelled so it allows them all to be cleared fro the queue now and listeners can get notified.

        // We want to make it so the next time the developer calls runTasks(), 0 tasks get run. To do that, you must run the queue to have all tasks deleted after they are marked as invalid.
        await runTasks()
    }

    public func addQueueReader(_ reader: QueueReader) {
        DIGraph.shared.pendingTasksManager.addQueueReader(reader)
    }

    public struct InitializedData: AutoResettable {
        var taskRunner: WendyTaskRunner?
    }

    final class DataStore: InMemoryDataStore<InitializedData>, Singleton {
        static let shared = DataStore(data: .init())
    }
}

extension DIGraph {
    var taskRunner: WendyTaskRunner? {
        Wendy.shared.taskRunner
    }
}
