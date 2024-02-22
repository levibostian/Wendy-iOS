import CoreData
import Foundation

// sourcery: InjectRegister = "PendingTasksManager"
// sourcery: InjectSingleton
internal class PendingTasksManager: QueueReader, QueueWriter {
    
    private let queueWriter: QueueWriter
    
    internal var queueReaders: [QueueReader] = []
    
    init(queueWriter: QueueWriter, queueReader: QueueReader) {
        self.queueWriter = queueWriter
        
        self.queueReaders = [
            queueReader
        ]
    }

    func add(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        return queueWriter.add(tag: tag, dataId: dataId, groupId: groupId)
    }

    internal func getAllTasks() -> [PendingTask] {
        return queueReaders.flatMap { return $0.getAllTasks() }
            .filter { return $0.createdAt != nil }
            .sorted(by: { $0.createdAt! < $1.createdAt! })
    }

    internal func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        return queueReaders.compactMap { return $0.getTaskByTaskId(taskId) }.first
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    @discardableResult
    func delete(taskId: Double) -> Bool {
        return queueWriter.delete(taskId: taskId)
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        return queueReaders.compactMap { reader in
            return reader.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter)
        }.first
    }
    
    public func addQueueReader(_ queueReader: QueueReader) {
        queueReaders.append(queueReader)
    }
    
}
