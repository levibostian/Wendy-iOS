import Foundation

// A writer, that stores data in the form of files on the file system.
// sourcery: InjectRegister = "QueueWriter"
// sourcery: InjectSingleton
public class FileSystemQueueWriter: QueueWriter {
    private let mutex = Mutex()
    private let queue: FileSystemQueue
    private let jsonAdapter: JsonAdapter

    init(queue: FileSystemQueue, jsonAdapter: JsonAdapter) {
        self.queue = queue
        self.jsonAdapter = jsonAdapter
    }

    public func add(tag: String, data: some Decodable & Encodable, groupId: String?) -> PendingTask {
        mutex.lock()
        defer { mutex.unlock() }

        let newTaskId = PendingTasksUtil.getNextPendingTaskId() // same that the coredata store uses.
        let newCreatedAt = Date()
        let newPendingTask = PendingTask(tag: tag, taskId: newTaskId, data: jsonAdapter.toData(data), groupId: groupId, createdAt: newCreatedAt)

        queue.add(newPendingTask)

        return newPendingTask
    }

    public func delete(taskId: Double) -> Bool {
        mutex.lock()
        defer { mutex.unlock() }

        queue.delete(taskId)

        return false
    }
}
