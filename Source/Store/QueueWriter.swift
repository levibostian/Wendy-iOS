import Foundation

public protocol QueueWriter {
    func add(tag: String, data: some Codable, groupId: String?) -> PendingTask
    func delete(taskId: Double) -> Bool
}

public extension QueueWriter {
    func delete(task: PendingTask) -> Bool {
        delete(taskId: task.taskId!)
    }
}
