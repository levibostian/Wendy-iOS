import Foundation

final public class Wendy: Sendable {
    
    public static let shared: Wendy = Wendy()
    
    private let initializedData: MutableSendable<InitializedData?> = MutableSendable(nil)
    
    internal var taskRunner: WendyTaskRunnerConcurrency? {
        initializedData.get()?.taskRunner
    }
    
    private var pendingTasksRunner: PendingTasksRunner {
        DIGraph.shared.pendingTasksRunner
    }

    private init() {}
    
    internal static func reset() { // for testing
        Self.shared.initializedData.set(nil)
    }

    @MainActor
    public class func setup(taskRunner: WendyTaskRunner, debug: Bool = false) {
        Wendy.shared.initializedData.set(InitializedData(taskRunner: LegayTaskRunnerAdapter(taskRunner: taskRunner)))
        WendyConfig.debug = debug
        
        // TODO: load the queue cache so it's ready to use.
        // Disabled for now while the file system queue code is still being developed.
        // FileSystemQueueImpl.shared.load()
    }
    
    @MainActor
    public class func setup(taskRunner: WendyTaskRunnerConcurrency, debug: Bool = false) {
        Wendy.shared.initializedData.set(InitializedData(taskRunner: taskRunner))
        WendyConfig.debug = debug
        
        // TODO: load the queue cache so it's ready to use.
        // Disabled for now while the file system queue code is still being developed.
        // FileSystemQueueImpl.shared.load()
    }
    
    public func addTask(tag: String, dataId: String?, groupId: String? = nil) -> Double {
        let addedTask = DIGraph.shared.pendingTasksManager.add(tag: tag, dataId: dataId, groupId: groupId)

        LogUtil.logNewTaskAdded(addedTask)

        return addedTask.taskId!
    }
    
    public func runTask(_ taskId: Double) async -> TaskRunResult {
        guard let _ = DIGraph.shared.pendingTasksManager.getTaskByTaskId(taskId) else {
            return .cancelled
        }
        
        let result = await pendingTasksRunner.runTask(taskId: taskId)

        return result
    }

    public func runTask(_ taskId: Double, onComplete: (@Sendable (TaskRunResult) -> Void)?) {
        Task {
            let result = await self.runTask(taskId)

            onComplete?(result)
        }
    }
    
    public func runTasks(filter: RunAllTasksFilter? = nil) async -> PendingTasksRunnerResult {
        let result = await pendingTasksRunner.runAllTasks(filter: filter)
        
        return result
    }

    public func runTasks(filter: RunAllTasksFilter? = nil, onComplete: (@Sendable (PendingTasksRunnerResult) -> Void)?) {
        Task {
            let result = await self.runTasks(filter: filter)
            
            onComplete?(result)
        }
    }

    public func getAllTasks() -> [PendingTask] {
        return DIGraph.shared.pendingTasksManager.getAllTasks()
    }

    /**
     Sets pending tasks that are in the queue to run as cancelled. Tasks are all still queued, but will be deleted and skipped to run when the task runner encounters them.

     Note: If a task is currently running when clear() is called, that running task will be finish executing but will not run again in the future as it has been cancelled.
     */
    public func clear() {
        /// It's not possible to stop a dispatch queue of tasks so there is no way to stop the currently running task runner.
        /// This solution of using UserDefaults to set a threshold solves that problem while also leaving Wendy untouched to continue running as usual. If we deleted all data, as Android's Wendy does, we would have potential issues with tasks that are still in the queue but core data and userdefaults being deleted causing potential crashes and IDs being misaligned.
        PendingTasksUtil.setValidPendingTasksIdThreshold()
        LogUtil.d("Wendy tasks set as cancelled. Currently scheduled Wendy tasks will all skip running.")
        // Run all tasks (including manually run tasks) as they are all cancelled so it allows them all to be cleared fro the queue now and listeners can get notified.
        getAllTasks().forEach { task in
            self.runTask(task.taskId!, onComplete: nil)
        }
    }
    
    public func addQueueReader(_ reader: QueueReader) {
        DIGraph.shared.pendingTasksManager.addQueueReader(reader)
    }
    
    struct InitializedData {
        let taskRunner: WendyTaskRunnerConcurrency
    }
}

extension DIGraph {
    var taskRunner: WendyTaskRunnerConcurrency? {
        return Wendy.shared.taskRunner
    }
}
