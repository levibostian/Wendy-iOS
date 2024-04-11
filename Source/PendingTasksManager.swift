import CoreData
import Foundation

// sourcery: InjectRegister = "PendingTasksManager"
// sourcery: InjectSingleton
final class PendingTasksManager: QueueReader, QueueWriter, Sendable {
    private let queueWriter: MutableSendable<QueueWriter>

    let queueReaders: MutableSendable<[QueueReader]> = MutableSendable([])

    init(queueWriter: QueueWriter, queueReader: QueueReader) {
        self.queueWriter = MutableSendable(queueWriter)

        queueReaders.set([
            queueReader
        ])
    }

    func add(tag: String, data: some Decodable & Encodable, groupId: String?) -> PendingTask {
        queueWriter.get().add(tag: tag, data: data, groupId: groupId)
    }

    func getAllTasks() -> [PendingTask] {
        queueReaders.get().flatMap { $0.getAllTasks() }
            .filter { $0.createdAt != nil }
            .sorted(by: { $0.createdAt! < $1.createdAt! })
    }

    func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        queueReaders.get().compactMap { $0.getTaskByTaskId(taskId) }.first
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    @discardableResult
    func delete(taskId: Double) -> Bool {
        queueWriter.get().delete(taskId: taskId)
    }

    func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        queueReaders.get().compactMap { reader in
            reader.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter)
        }.first
    }

    public func addQueueReader(_ queueReader: QueueReader) {
        queueReaders.set { existingReaders in
            existingReaders + [queueReader]
        }
    }
}
