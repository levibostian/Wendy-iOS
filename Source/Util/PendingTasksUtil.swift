import Foundation

class PendingTasksUtil {
    private static let prefix = "pendingTasks_"
    private static let pendingTasksNextPendingTaskIdKey = "\(prefix)pendingTasksNextPendingTaskIdKey"
    /// Tasks with id >= validPendingTasksIdThreshold are valid. < are invalid.
    private static let validPendingTasksIdThresholdKey = "\(prefix)validPendingTasksIdThresholdKey"

    private static var currentPendingTaskId: Double {
        UserDefaults.standard.double(forKey: pendingTasksNextPendingTaskIdKey)
    }

    private static var validPendingTasksIdThreshold: Double {
        UserDefaults.standard.double(forKey: validPendingTasksIdThresholdKey)
    }

    class func isTaskValid(taskId: Double) -> Bool {
        taskId >= validPendingTasksIdThreshold
    }

    class func getNextPendingTaskId() -> Double {
        let nextPendingTaskId = currentPendingTaskId + 1
        UserDefaults.standard.set(nextPendingTaskId, forKey: pendingTasksNextPendingTaskIdKey)
        return nextPendingTaskId
    }

    class func setValidPendingTasksIdThreshold() {
        UserDefaults.standard.set(currentPendingTaskId + 1, forKey: validPendingTasksIdThresholdKey)
    }
}
