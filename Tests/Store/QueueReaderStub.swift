import Foundation
@testable import Wendy

class QueueReaderStub: QueueReader {
    var allTasks: [PendingTask] = []

    func getAllTasks() -> [PendingTask] {
        allTasks
    }

    func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        allTasks.first { $0.taskId == taskId }
    }

    func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        allTasks.first
    }
}
