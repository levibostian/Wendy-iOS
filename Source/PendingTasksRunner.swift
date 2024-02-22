import Foundation

/**
 Requirements of the task runner:

 1. when you call `Wendy.runTask()` it returns instantly to you. It does *not* block the calling thread. It's like it schedules a job to run in the future.
 2. X number of threads all running the task runner's `runTask()` function can only run one at a time. (so, run runTask() in a sync way)
 3. The task runner's `runTask()` runs in a sync way (while the `PendingTask.runTask()` is async) where it does not return a result until the task has failed or succeeded. So, work in a blocking way.
 */
// sourcery: InjectRegister = "PendingTasksRunner"
// sourcery: InjectSingleton
internal class PendingTasksRunner {

    private var lastSuccessfulOrFailedTaskId: Double = 0
    private var failedTasksGroups: [String] = []
    internal var currentlyRunningTask: PendingTask?
    
    private let pendingTasksManager: PendingTasksManager
    
    init(pendingTasksManager: PendingTasksManager) {
        self.pendingTasksManager = pendingTasksManager
    }

    // I created a separate class for running a single pending task simply as a wrapper to the function runPendingTask(taskId).
    // this function is very important to have it run in a synchronized way and to enforce that, I need to make sure it uses a DispatchQueue to run all of it's callers requests. So, I created this class to make sure I don't make the mistake of accidently calling this `runPendingTask(taskId)` function inside of the `PendingTasksRunner` without following my rule of *this function must run in a synchonized way!* (I already made this mistake....)
    fileprivate class RunSinglePendingTaskRunner {
        static var shared = RunSinglePendingTaskRunner()
        
        private var pendingTasksRunner: PendingTasksRunner {
            DIGraph.shared.pendingTasksRunner
        }
        private var pendingTasksManager: PendingTasksManager {
            DIGraph.shared.pendingTasksManager
        }

        private let runPendingTaskDispatchQueue = DispatchQueue(label: "com.levibostian.wendy.PendingTasksRunner.Scheduler.runPendingTask")
        private let runTaskDispatchGroup = DispatchGroup()

        private init() {}

        fileprivate func scheduleRunPendingTask(_ taskId: Double, onComplete: @escaping (TaskRunResult) -> Void) {
            runPendingTaskDispatchQueue.async {
                let result = self.runPendingTask(taskId: taskId)
                onComplete(result)
            }
        }

        fileprivate func runPendingTaskWait(_ taskId: Double) -> TaskRunResult {
            return runPendingTaskDispatchQueue.sync { () -> TaskRunResult in
                self.runPendingTask(taskId: taskId)
            }
        }

        /**
         * @throws when in [WendyConfig.strict] mode and you say that your [PendingTask] was [PendingTaskResult.SUCCESSFUL] when you have an unresolved error recorded for that [PendingTask].
         */
        private func runPendingTask(taskId: Double) -> TaskRunResult { // swiftlint:disable:this function_body_length
            runTaskDispatchGroup.enter()
            var runTaskResult: TaskRunResult!

            guard let taskToRun = pendingTasksManager.getTaskByTaskId(taskId) else {
                runTaskResult = TaskRunResult.cancelled

                runTaskDispatchGroup.leave()
                return runTaskResult // This code should *not* be executed because of .leave() above.
            }

            if !PendingTasksUtil.isTaskValid(taskId: taskId) {
                LogUtil.d("Task: \(taskToRun.describe()) is cancelled. Deleting the task.")
                pendingTasksManager.delete(taskId: taskId)
                runTaskResult = TaskRunResult.cancelled
                WendyConfig.logTaskComplete(taskToRun, successful: true, cancelled: true)

                runTaskDispatchGroup.leave()
                return runTaskResult // This code should *not* be executed because of .leave() above.
            }

            pendingTasksRunner.currentlyRunningTask = taskToRun

            WendyConfig.logTaskRunning(taskToRun)
            LogUtil.d("Running task: \(taskToRun.describe())")
            
            Wendy.shared.taskRunner?.runTask(tag: taskToRun.tag, dataId: taskToRun.dataId, complete: { error in
                let successful = error == nil
                self.pendingTasksRunner.currentlyRunningTask = nil

                if let error = error {
                    LogUtil.d("Task: \(taskToRun.describe()) failed but will reschedule it. Skipping it.")
                    WendyConfig.logTaskComplete(taskToRun, successful: false, cancelled: false)
                    runTaskResult = TaskRunResult.failure(error: error)

                    self.runTaskDispatchGroup.leave()
                    return
                }

                LogUtil.d("Task: \(taskToRun.describe()) ran successful.")
                LogUtil.d("Deleting task: \(taskToRun.describe()).")
                self.pendingTasksManager.delete(taskId: taskId)

                WendyConfig.logTaskComplete(taskToRun, successful: successful, cancelled: false)

                runTaskResult = TaskRunResult.successful

                self.runTaskDispatchGroup.leave()
                return
            })

            _ = runTaskDispatchGroup.wait(timeout: .distantFuture)
            return runTaskResult
        }
    }

    /**
     **Note:** Make sure you call this function from a background thread! You are in charge of doing that, not this function. This function returns a result and behaves in a syncrhonized way so it is not responsible for what thread to run on.

     Note: Do not pass in a value for `result` parameter. that is for recusion purposes only.

     Example: Check out PendingTasksRunner.Scheduler.scheduleRunAllTasks()
     */
    internal func runAllTasks(filter: RunAllTasksFilter?, result: PendingTasksRunnerResult = PendingTasksRunnerResult.new()) -> PendingTasksRunnerResult {
        LogUtil.d("Getting next task to run.")

        guard let nextTaskToRun = pendingTasksManager.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter) else {
            LogUtil.d("All done running tasks.")
            WendyConfig.logAllTasksComplete()

            resetRunner()
            return result
        }

        lastSuccessfulOrFailedTaskId = nextTaskToRun.taskId!
        if nextTaskToRun.groupId != nil && failedTasksGroups.contains(nextTaskToRun.groupId!) {
            WendyConfig.logTaskSkipped(nextTaskToRun, reason: ReasonPendingTaskSkipped.partOfFailedGroup)
            LogUtil.d("Task: \(nextTaskToRun.describe()) belongs to a failing group of tasks. Skipping it.")
            return runAllTasks(filter: filter, result: result)
        }

        let jobRunResult = Scheduler.shared.runPendingTaskWait(nextTaskToRun.taskId!)
        switch jobRunResult {
        case .successful, .cancelled:
            // cancelled is treated like successful. Once cancelled, we ignore it and go onto the next.
            return runAllTasks(filter: filter, result: result.addResult(jobRunResult))
        case .failure:
            if let taskGroupId = nextTaskToRun.groupId {
                failedTasksGroups.append(taskGroupId)
            }
            return runAllTasks(filter: filter, result: result.addResult(jobRunResult))
        case .skipped(_):
            return runAllTasks(filter: filter, result: result.addResult(jobRunResult))
        }
    }

    private func resetRunner() {
        lastSuccessfulOrFailedTaskId = 0
        failedTasksGroups = []
        currentlyRunningTask = nil
    }

    internal class Scheduler {
        static var shared = Scheduler()
        
        private var pendingTasksRunner: PendingTasksRunner {
            DIGraph.shared.pendingTasksRunner
        }

        fileprivate let runPendingTasksDispatchQueue = DispatchQueue(label: "com.levibostian.wendy.PendingTasksRunner.Scheduler.runPendingTasks")

        private init() {}

        internal func runPendingTaskWait(_ taskId: Double) -> TaskRunResult {
            return RunSinglePendingTaskRunner.shared.runPendingTaskWait(taskId)
        }

        internal func scheduleRunPendingTask(_ taskId: Double, onComplete: @escaping (TaskRunResult) -> Void) {
            RunSinglePendingTaskRunner.shared.scheduleRunPendingTask(taskId, onComplete: onComplete)
        }

        internal func scheduleRunAllTasks(filter: RunAllTasksFilter?, onComplete: @escaping (PendingTasksRunnerResult) -> Void) {
            runPendingTasksDispatchQueue.async {
                LogUtil.d("Running all tasks in task runner \((filter != nil) ? " (with filter)" : "").")
                let result = self.pendingTasksRunner.runAllTasks(filter: filter)
                onComplete(result)
            }
        }

        internal func scheduleRunAllTasksWait(filter: RunAllTasksFilter?) -> PendingTasksRunnerResult {
            return runPendingTasksDispatchQueue.sync { () -> PendingTasksRunnerResult in
                LogUtil.d("Running all tasks in task runner \((filter != nil) ? " (with filter)" : "").")
                return pendingTasksRunner.runAllTasks(filter: filter)
            }
        }
    }
}
