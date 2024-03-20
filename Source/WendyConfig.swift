import Foundation

public final class WendyConfig: Sendable {
    let _logTag = MutableSendable("WENDY")
    let _strict = MutableSendable(true)
    let _debug = MutableSendable(false)
    let _automaticallyRunTasks = MutableSendable(true)
    
    internal var taskRunnerListeners: [WeakReferenceTaskRunnerListener] {
        get { _taskRunnerListeners.get() }
        set { _taskRunnerListeners.set(newValue) }
    }
    let _taskRunnerListeners = MutableSendable([WeakReferenceTaskRunnerListener]())

    internal var taskStatusListeners: [TaskStatusListener] {
        get { _taskStatusListeners.get() }
        set { _taskStatusListeners.set(newValue) }
    }
    let _taskStatusListeners = MutableSendable([TaskStatusListener]())

    internal class func getTaskStatusListenerForTask(_ taskId: Double) -> [WeakReferencePendingTaskStatusListener] {
        return Wendy.config.taskStatusListeners.filter { (listener) -> Bool in
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

// Public API to modify WendyConfig
public extension WendyConfig {
    static var logTag: String {
        get { Wendy.config._logTag.get() }
        set { Wendy.config._logTag.set(newValue) }
    }
    
    static var strict: Bool {
        get { Wendy.config._strict.get() }
        set { Wendy.config._strict.set(newValue) }
    }
    
    static var debug: Bool {
        get { Wendy.config._debug.get() }
        set { Wendy.config._debug.set(newValue) }
    }
    
    static var automaticallyRunTasks: Bool {
        get { Wendy.config._automaticallyRunTasks.get() }
        set { Wendy.config._automaticallyRunTasks.set(newValue) }
    }
    
    class func addTaskRunnerListener(_ listener: TaskRunnerListener) {
        Wendy.config._taskRunnerListeners.set { $0 + [WeakReferenceTaskRunnerListener(listener: listener)] }
    }
    
    class func addTaskStatusListenerForTask(_ taskId: Double, listener: PendingTaskStatusListener) {
        Wendy.config._taskStatusListeners.set { $0 + [TaskStatusListener(taskId: taskId, weakRefListener: WeakReferencePendingTaskStatusListener(listener: listener))] }

        // The task runner could be running this task right now and because it takes a while potentially to run a task, I need to notify the listener here. This should be the only use case to handle here, running of a task.
        if Wendy.shared.currentlyRunningTask?.taskId == taskId {
            listener.running(taskId: taskId)
        }
    }
}
