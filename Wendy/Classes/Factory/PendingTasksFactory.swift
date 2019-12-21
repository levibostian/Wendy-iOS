import Foundation

public protocol PendingTasksFactory {
    func getTask(tag: PendingTask.Tag) -> PendingTask
}
