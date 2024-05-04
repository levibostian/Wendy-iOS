import Foundation

// A writer, that stores data in the form of files on the file system.
// sourcery: InjectRegister = "QueueWriter"
public class FileSystemQueueWriter: QueueWriter {
    private let queue: FileSystemQueue
    private let jsonAdapter: JsonAdapter

    private var mutex: Mutex {
        Mutex.Store.shared.getMutex(for: self)
    }

    init(queue: FileSystemQueue, jsonAdapter: JsonAdapter) {
        self.queue = queue
        self.jsonAdapter = jsonAdapter
    }

    public func add(tag: String, data: some Decodable & Encodable, groupId: String?) -> PendingTask {
        mutex.lock()
        defer { mutex.unlock() }

        // Important that only 1 thread can access this function at a time. Otherwise, we run the risk of non-uniqueue tasks being created.
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
