import Foundation

public enum WendyConfig {
    static var logTag: String {
        get { getConfig.logTag }
        set { setConfig { $0.logTag = newValue } }
    }

    static var strict: Bool {
        get { getConfig.strict }
        set { setConfig { $0.strict = newValue } }
    }

    static var debug: Bool {
        get { getConfig.debug }
        set { setConfig { $0.debug = newValue } }
    }

    static var automaticallyRunTasks: Bool {
        get { getConfig.automaticallyRunTasks }
        set { setConfig { $0.automaticallyRunTasks = newValue } }
    }

    static var taskRunnerListeners: [WeakReferenceTaskRunnerListener] {
        get { getConfig.taskRunnerListeners }
        set { setConfig { $0.taskRunnerListeners = newValue } }
    }

    static var taskStatusListeners: [TaskStatusListener] {
        get { getConfig.taskStatusListeners }
        set { setConfig { $0.taskStatusListeners = newValue } }
    }

    static var semaphoreValue: Int {
        get { getConfig.semaphoreValue }
        set { setConfig { $0.semaphoreValue = newValue } }
    }

    public static func addTaskRunnerListener(_ listener: TaskRunnerListener) {
        setConfig { $0.taskRunnerListeners.append(WeakReferenceTaskRunnerListener(listener: listener)) }
    }

    public static func addTaskStatusListenerForTask(_ taskId: Double, listener: PendingTaskStatusListener) {
        setConfig { $0.taskStatusListeners.append(TaskStatusListener(taskId: taskId, weakRefListener: WeakReferencePendingTaskStatusListener(listener: listener))) }

        // The task runner could be running this task right now and because it takes a while potentially to run a task, I need to notify the listener here. This should be the only use case to handle here, running of a task.
        if Wendy.shared.currentlyRunningTask?.taskId == taskId {
            listener.running(taskId: taskId)
        }
    }

    static func getTaskStatusListenerForTask(_ taskId: Double) -> [WeakReferencePendingTaskStatusListener] {
        getConfig.taskStatusListeners.filter { listener -> Bool in
            listener.taskId == taskId
        }.map { taskStatusListener -> WeakReferencePendingTaskStatusListener in
            taskStatusListener.weakRefListener
        }
    }

    struct TaskStatusListener {
        let taskId: Double
        let weakRefListener: WeakReferencePendingTaskStatusListener
    }

    public struct Data: AutoResettable {
        var logTag: String = "WENDY"
        var strict: Bool = true
        var debug: Bool = false
        var automaticallyRunTasks: Bool = true
        var taskRunnerListeners: [WeakReferenceTaskRunnerListener] = []
        var taskStatusListeners: [TaskStatusListener] = []
        var semaphoreValue: Int = 1
    }

    final class DataStore: InMemoryDataStore<Data>, Singleton {
        static let shared: DataStore = .init(data: .init())
    }
}

extension WendyConfig {
    private static var getConfig: Data {
        DataStore.shared.getDataSnapshot()
    }

    private static func setConfig(_ block: (inout WendyConfig.Data) -> Void) {
        DataStore.shared.updateDataBlock(block)
    }
}
