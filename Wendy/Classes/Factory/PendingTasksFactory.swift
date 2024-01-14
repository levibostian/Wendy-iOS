import Foundation

public protocol PendingTasksFactory {
    func getTask(tag: String) -> PendingTask
}
