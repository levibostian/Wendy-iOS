import Foundation
import Semaphore

public extension Wendy {
    var currentlyRunningTask: PendingTask? {
        DIGraph.shared.pendingTasksRunner.currentlyRunningTask.get()
    }
}

/**
 Requirements of the task runner:

 1. when you call `Wendy.runTask()` it returns instantly to you. It does *not* block the calling thread. It's like it schedules a job to run in the future.
 2. X number of threads all running the task runner's `runTask()` function can only run one at a time. (so, run runTask() in a sync way)
 3. The task runner's `runTask()` runs in a sync way (while the `PendingTask.runTask()` is async) where it does not return a result until the task has failed or succeeded. So, work in a blocking way.
 */
// sourcery: InjectRegister = "PendingTasksRunner"
// sourcery: InjectSingleton
public final class PendingTasksRunner: Sendable {
    
    private let runAllTasksLock = RunAllTasksLock()
    
    private let pendingTasksManager: PendingTasksManager
    
    public let currentlyRunningTask: MutableSendable<PendingTask?> = MutableSendable(nil)
    
    private var taskRunner: WendyTaskRunnerConcurrency? {
        DIGraph.shared.taskRunner
    }
    
    private let runTaskSemaphore = AsyncSemaphore(value: 1)
    
    init(pendingTasksManager: PendingTasksManager) {
        self.pendingTasksManager = pendingTasksManager
    }

        /**
         Runs 1 task and returns the result.
         
         Guarantees:
         * Will only run 1 task at a time. Your request may need to wait in order for it to begin running. The function call will return after the wait period + time it took to run the task.
         * Runs the request in a background thread.
         */
    internal func runTask(taskId: Double) async -> TaskRunResult {
            guard let taskRunner else {
                return .cancelled
            }
            
            await runTaskSemaphore.wait()
        
            var runTaskResult: TaskRunResult!

            guard let taskToRun = pendingTasksManager.getTaskByTaskId(taskId) else {
                runTaskResult = TaskRunResult.cancelled

                runTaskSemaphore.signal()
                return runTaskResult
            }

            if !PendingTasksUtil.isTaskValid(taskId: taskId) {
                LogUtil.d("Task: \(taskToRun.describe()) is cancelled. Deleting the task.")
                pendingTasksManager.delete(taskId: taskId)
                runTaskResult = TaskRunResult.cancelled
                LogUtil.logTaskComplete(taskToRun, successful: true, cancelled: true)

                runTaskSemaphore.signal()
                return runTaskResult
            }

        self.currentlyRunningTask.set(taskToRun)

            LogUtil.logTaskRunning(taskToRun)
            LogUtil.d("Running task: \(taskToRun.describe())")
            
                do {
                    try await taskRunner.runTask(tag: taskToRun.tag, data: taskToRun.data)
                    
                    self.currentlyRunningTask.set(nil)
                    
                    LogUtil.d("Task: \(taskToRun.describe()) ran successful.")
                    LogUtil.d("Deleting task: \(taskToRun.describe()).")
                    self.pendingTasksManager.delete(taskId: taskId)
                    LogUtil.logTaskComplete(taskToRun, successful: true, cancelled: false)
                    
                    self.runTaskSemaphore.signal()
                    return .successful
                } catch (let error) {
                    self.currentlyRunningTask.set(nil)
                    LogUtil.d("Task: \(taskToRun.describe()) failed but will reschedule it. Skipping it.")
                    LogUtil.logTaskComplete(taskToRun, successful: false, cancelled: false)
                    
                    self.runTaskSemaphore.signal()
                    return .failure(error: error)
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
        if await runAllTasksLock.requestToRunAllTasks() == false {
            return .new() // return a result that says that 0 tasks were executed. Which, is true.
        }
        
        var nextTaskToRun: PendingTask?
        var runAllTasksResult = PendingTasksRunnerResult.new()
        var lastSuccessfulOrFailedTaskId: Double = 0
        var failedTasksGroups: [String] = []
        
        repeat {
            nextTaskToRun = pendingTasksManager.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter)
            guard let nextTaskToRun else {
                break
            }
            
            lastSuccessfulOrFailedTaskId = nextTaskToRun.taskId!
            if nextTaskToRun.groupId != nil && failedTasksGroups.contains(nextTaskToRun.groupId!) {
                LogUtil.logTaskSkipped(nextTaskToRun, reason: ReasonPendingTaskSkipped.partOfFailedGroup)
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
        LogUtil.logAllTasksComplete()
        
        await runAllTasksLock.unlock()
        
        return runAllTasksResult
    }
    
    actor RunAllTasksLock {
        private var isRunningAllTasks = false
        
        func requestToRunAllTasks() async -> Bool {
            if isRunningAllTasks {
                return false
            }
            
            isRunningAllTasks = true
            return true
        }
        
        func unlock() {
            isRunningAllTasks = false
        }
    }
}
