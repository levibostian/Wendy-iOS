import Foundation

public class WendyConfig {
    public static var logTag: String = "WENDY"
    public static var automaticallyRunTasks: Bool = true
    public static var strict: Bool = true
    public static var debug: Bool = false
    public static var collections: Collections = [:]

    fileprivate static var taskRunnerListeners: [WeakReferenceTaskRunnerListener] = []
    public class func addTaskRunnerListener(_ listener: TaskRunnerListener) {
        taskRunnerListeners.append(WeakReferenceTaskRunnerListener(listener: listener))
    }

    private static var taskStatusListeners: [TaskStatusListener] = []
    public class func addTaskStatusListenerForTask(_ taskId: Double, listener: PendingTaskStatusListener) {
        taskStatusListeners.append(TaskStatusListener(taskId: taskId, weakRefListener: WeakReferencePendingTaskStatusListener(listener: listener)))

        // The task runner could be running this task right now and because it takes a while potentially to run a task, I need to notify the listener here. This should be the only use case to handle here, running of a task.
        let taskRunner: PendingTasksRunner = PendingTasksRunner.shared
        if taskRunner.currentlyRunningTask?.id == taskId {
            listener.running(taskId: taskId)
        }
        if let latestError = Wendy.shared.getLatestError(taskId: taskId) {
            listener.errorRecorded(taskId: taskId, errorMessage: latestError.errorMessage, errorId: latestError.errorId)
        }
    }

    internal class func getTaskStatusListenerForTask(_ taskId: Double) -> [WeakReferencePendingTaskStatusListener] {
        return taskStatusListeners.filter { (listener) -> Bool in
            listener.taskId == taskId
        }.map { (taskStatusListener) -> WeakReferencePendingTaskStatusListener in
            taskStatusListener.weakRefListener
        }
    }

    private struct TaskStatusListener {
        let taskId: Double
        let weakRefListener: WeakReferencePendingTaskStatusListener
    }
}

internal extension WendyConfig {
    class func logNewTaskAdded(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                weakRefListener.listener.newTaskAdded(task)
            }
        }
    }

    class func logTaskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                weakRefListener.listener.taskSkipped(task, reason: reason)
            }
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                weakRefListener.listener?.skipped(taskId: task.taskId!, reason: reason)
            }
        }
    }

    class func logTaskComplete(_ task: PendingTask, successful: Bool, cancelled: Bool) {
        let successful = (successful || cancelled) // to make sure that cancelled marks succcessful as successful, always.

        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                weakRefListener.listener.taskComplete(task, successful: successful, cancelled: cancelled)
            }
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                weakRefListener.listener?.complete(taskId: task.taskId!, successful: successful, cancelled: cancelled)
            }
        }
    }

    class func logTaskRunning(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                weakRefListener.listener.runningTask(task)
            }
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                weakRefListener.listener?.running(taskId: task.taskId!)
            }
        }
    }

    class func logErrorRecorded(_ task: PendingTask, errorMessage: String?, errorId: String?) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                weakRefListener.listener.errorRecorded(task, errorMessage: errorMessage, errorId: errorId)
            }
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                weakRefListener.listener?.errorRecorded(taskId: task.taskId!, errorMessage: errorMessage, errorId: errorId)
            }
        }
    }

    class func logErrorResolved(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                weakRefListener.listener.errorResolved(task)
            }
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                weakRefListener.listener?.errorResolved(taskId: task.taskId!)
            }
        }
    }

    class func logAllTasksComplete() {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                weakRefListener.listener.allTasksComplete()
            }
        }
    }
}
