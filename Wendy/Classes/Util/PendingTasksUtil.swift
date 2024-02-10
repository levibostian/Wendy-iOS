import Foundation

internal class PendingTasksUtil {
    private static let prefix = "pendingTasks_"
    private static let pendingTasksNextPendingTaskIdKey = "\(prefix)pendingTasksNextPendingTaskIdKey"
    // Tasks with id >= validPendingTasksIdThreshold are valid. < are invalid.
    private static let validPendingTasksIdThresholdKey = "\(prefix)validPendingTasksIdThresholdKey"

    private static var currentPendingTaskId: Double {
        return UserDefaults.standard.double(forKey: pendingTasksNextPendingTaskIdKey)
    }

    private static var validPendingTasksIdThreshold: Double {
        return UserDefaults.standard.double(forKey: validPendingTasksIdThresholdKey)
    }

    internal class func isTaskValid(taskId: Double) -> Bool {
        return taskId >= validPendingTasksIdThreshold
    }

    internal class func getNextPendingTaskId() -> Double {
        let nextPendingTaskId = currentPendingTaskId + 1
        UserDefaults.standard.set(nextPendingTaskId, forKey: pendingTasksNextPendingTaskIdKey)
        return nextPendingTaskId
    }

    internal class func setValidPendingTasksIdThreshold() {
        UserDefaults.standard.set(currentPendingTaskId + 1, forKey: validPendingTasksIdThresholdKey)
    }
}
