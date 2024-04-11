import Foundation

public protocol QueueWriter {
    func add<Data: Codable>(tag: String, data: Data, groupId: String?) -> PendingTask
    func delete(taskId: Double) -> Bool
}

public extension QueueWriter {
    func delete(task: PendingTask) -> Bool {
        delete(taskId: task.taskId!)
    }
}
