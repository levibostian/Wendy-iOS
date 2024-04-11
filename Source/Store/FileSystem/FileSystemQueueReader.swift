import Foundation

// sourcery: InjectRegister = "QueueReader"
// sourcery: InjectSingleton
public class FileSystemQueueReader: QueueReader {
    private let queue: FileSystemQueue

    init(queue: FileSystemQueue) {
        self.queue = queue
    }

    public func getAllTasks() -> [PendingTask] {
        queue.queue
    }

    public func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        queue.queue.first(where: { $0.taskId == taskId })
    }

    public func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        var potentialTasksToRun = queue.queue
        potentialTasksToRun = potentialTasksToRun.filter {
            guard let taskId = $0.taskId else { return false }
            return taskId > lastSuccessfulOrFailedTaskId
        }

        if let filter {
            switch filter {
            case .group(let groupId):
                potentialTasksToRun = potentialTasksToRun.filter {
                    $0.groupId == groupId
                }
            }
        }

        return potentialTasksToRun.first
    }
}
