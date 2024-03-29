import CoreData
import Foundation

// sourcery: InjectRegister = "PendingTasksManager"
// sourcery: InjectSingleton
internal final class PendingTasksManager: QueueReader, QueueWriter, Sendable {
    
    private let queueWriter: MutableSendable<QueueWriter>
    
    internal let queueReaders: MutableSendable<[QueueReader]> = MutableSendable([])
    
    init(queueWriter: QueueWriter, queueReader: QueueReader) {
        self.queueWriter = MutableSendable(queueWriter)
        
        self.queueReaders.set([
            queueReader
        ])
    }

    func add<Data>(tag: String, data: Data, groupId: String?) -> PendingTask where Data : Decodable, Data : Encodable {
        return queueWriter.get().add(tag: tag, data: data, groupId: groupId)
    }

    internal func getAllTasks() -> [PendingTask] {
        return queueReaders.get().flatMap { return $0.getAllTasks() }
            .filter { return $0.createdAt != nil }
            .sorted(by: { $0.createdAt! < $1.createdAt! })
    }

    internal func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        return queueReaders.get().compactMap { return $0.getTaskByTaskId(taskId) }.first
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    @discardableResult
    func delete(taskId: Double) -> Bool {
        return queueWriter.get().delete(taskId: taskId)
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        return queueReaders.get().compactMap { reader in
            return reader.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter)
        }.first
    }
    
    public func addQueueReader(_ queueReader: QueueReader) {
        queueReaders.set { existingReaders in
            return existingReaders + [queueReader]
        }
    }
    
}
