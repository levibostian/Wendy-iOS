import Foundation

public protocol QueueReader {
    func getAllTasks() -> [PendingTask]
    func getTaskByTaskId(_ taskId: Double) -> PendingTask?
    func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask?
}
