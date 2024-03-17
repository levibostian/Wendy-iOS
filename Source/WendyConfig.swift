import Foundation

@MainActor
public class WendyConfig {
    public static var logTag: String = "WENDY"
    public static var automaticallyRunTasks: Bool = true
    public static var strict: Bool = true
    public static var debug: Bool = false

    internal static var taskRunnerListeners: [WeakReferenceTaskRunnerListener] = []
    public class func addTaskRunnerListener(_ listener: TaskRunnerListener) {
        taskRunnerListeners.append(WeakReferenceTaskRunnerListener(listener: listener))
    }

    internal static var taskStatusListeners: [TaskStatusListener] = []
    public class func addTaskStatusListenerForTask(_ taskId: Double, listener: PendingTaskStatusListener) {
        taskStatusListeners.append(TaskStatusListener(taskId: taskId, weakRefListener: WeakReferencePendingTaskStatusListener(listener: listener)))

        // The task runner could be running this task right now and because it takes a while potentially to run a task, I need to notify the listener here. This should be the only use case to handle here, running of a task.
        if Wendy.shared.currentlyRunningTask?.taskId == taskId {
            listener.running(taskId: taskId)
        }
    }

    internal class func getTaskStatusListenerForTask(_ taskId: Double) -> [WeakReferencePendingTaskStatusListener] {
        return taskStatusListeners.filter { (listener) -> Bool in
            listener.taskId == taskId
        }.map { (taskStatusListener) -> WeakReferencePendingTaskStatusListener in
            taskStatusListener.weakRefListener
        }
    }

    internal struct TaskStatusListener {
        let taskId: Double
        let weakRefListener: WeakReferencePendingTaskStatusListener
    }
}
