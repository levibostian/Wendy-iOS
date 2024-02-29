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
    
    @Atomic private var isRunningAllTasks = false
    private let lock = Mutex()
    
    private let pendingTasksManager: PendingTasksManager
    
    private var taskRunner: WendyTaskRunner? {
        DIGraph.shared.taskRunner
    }
    
    private let runTaskSemaphore = DispatchSemaphore(value: 1)
    
    init(pendingTasksManager: PendingTasksManager) {
        self.pendingTasksManager = pendingTasksManager
    }
    
    private func resetRunner() {
        lastSuccessfulOrFailedTaskId = 0
        failedTasksGroups = []
        currentlyRunningTask = nil
    }
    
    internal func runTask(taskId: Double) async -> TaskRunResult {
        return await withCheckedContinuation { continuation in
            runTask(taskId: taskId) { result in
                continuation.resume(returning: result)
            }
        }
    }

        /**
         Runs 1 task and returns the result.
         
         Guarantees:
         * Will only run 1 task at a time. Your request may need to wait in order for it to begin running. The function call will return after the wait period + time it took to run the task.
         * Runs the request in a background thread.
         */
        internal func runTask(taskId: Double, onComplete: @escaping (TaskRunResult) -> Void) {
            guard let taskRunner else {
                onComplete(.cancelled)
                return
            }
            
            runTaskSemaphore.wait()
        
            var runTaskResult: TaskRunResult!

            guard let taskToRun = pendingTasksManager.getTaskByTaskId(taskId) else {
                runTaskResult = TaskRunResult.cancelled

                runTaskSemaphore.signal()
                onComplete(runTaskResult)
                return
            }

            if !PendingTasksUtil.isTaskValid(taskId: taskId) {
                LogUtil.d("Task: \(taskToRun.describe()) is cancelled. Deleting the task.")
                pendingTasksManager.delete(taskId: taskId)
                runTaskResult = TaskRunResult.cancelled
                WendyConfig.logTaskComplete(taskToRun, successful: true, cancelled: true)

                runTaskSemaphore.signal()
                onComplete(runTaskResult)
                return
            }

            self.currentlyRunningTask = taskToRun

            WendyConfig.logTaskRunning(taskToRun)
            LogUtil.d("Running task: \(taskToRun.describe())")
            
            taskRunner.runTask(tag: taskToRun.tag, dataId: taskToRun.dataId) { error in
                let successful = error == nil
                self.currentlyRunningTask = nil
                
                if let error = error {
                    LogUtil.d("Task: \(taskToRun.describe()) failed but will reschedule it. Skipping it.")
                    WendyConfig.logTaskComplete(taskToRun, successful: false, cancelled: false)
                    runTaskResult = TaskRunResult.failure(error: error)
                } else {
                    LogUtil.d("Task: \(taskToRun.describe()) ran successful.")
                    LogUtil.d("Deleting task: \(taskToRun.describe()).")
                    self.pendingTasksManager.delete(taskId: taskId)
                    WendyConfig.logTaskComplete(taskToRun, successful: successful, cancelled: false)
                    runTaskResult = TaskRunResult.successful
                }
                
                self.runTaskSemaphore.signal()
                onComplete(runTaskResult)
            }
        }

    /**
     Runs all tasks, allowing a filter to skip running some tasks.
     
     Guarantees:
     * Runs on a background thread.
     * Runs all tasks in a serial way, in order.
     * Only 1 runner is running at a time. If a runner is already running, this request will be ignored and returned instantly.
     */
    internal func runAllTasks(filter: RunAllTasksFilter?) async -> PendingTasksRunnerResult {
        lock.lock() // protect access to variable that determines if we are running already.
        
        if isRunningAllTasks {
            lock.unlock()
            return .new() // return a result that says that 0 tasks were executed. Which, is true.
        }
        
        isRunningAllTasks = true
        lock.unlock()
        
        var nextTaskToRun: PendingTask?
        var runAllTasksResult = PendingTasksRunnerResult.new()
        
        repeat {
            nextTaskToRun = pendingTasksManager.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter)
            guard let nextTaskToRun else {
                break
            }
            
            lastSuccessfulOrFailedTaskId = nextTaskToRun.taskId!
            if nextTaskToRun.groupId != nil && failedTasksGroups.contains(nextTaskToRun.groupId!) {
                WendyConfig.logTaskSkipped(nextTaskToRun, reason: ReasonPendingTaskSkipped.partOfFailedGroup)
                LogUtil.d("Task: \(nextTaskToRun.describe()) belongs to a failing group of tasks. Skipping it.")
                
                continue
            }

            let jobRunResult = await self.runTask(taskId: nextTaskToRun.taskId!)
            runAllTasksResult = runAllTasksResult.addResult(jobRunResult)
            
            if case .failure = jobRunResult, let taskGroupId = nextTaskToRun.groupId {
                failedTasksGroups.append(taskGroupId)
            }
        } while nextTaskToRun != nil

        LogUtil.d("All done running tasks.")
        WendyConfig.logAllTasksComplete()
        resetRunner()
        isRunningAllTasks = false
                
        return runAllTasksResult
    }
}
