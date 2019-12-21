import Foundation

internal class PendingTasksUtil {
    private static let prefix = "pendingTasks_"
    private static let pendingTasksNextPendingTaskIdKey = "\(prefix)pendingTasksNextPendingTaskIdKey"
    private static let rerunCurrentlyRunningPendingTaskKey = "\(prefix)rerunCurrentlyRunningPendingTaskKey"
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

    internal static var rerunCurrentlyRunningPendingTask: Bool {
        get {
            return UserDefaults.standard.double(forKey: rerunCurrentlyRunningPendingTaskKey) > 0
        }
        set {
            if newValue {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: rerunCurrentlyRunningPendingTaskKey)
            } else {
                UserDefaults.standard.set(0, forKey: rerunCurrentlyRunningPendingTaskKey)
            }
        }
    }

    internal class func getRerunCurrentlyRunningPendingTaskTime() -> Date? {
        guard let timeInternal: Double = UserDefaults.standard.double(forKey: rerunCurrentlyRunningPendingTaskKey), timeInternal > 0 else {
            return nil
        }

        return Date(timeIntervalSince1970: timeInternal)
    }

    internal class func resetRerunCurrentlyRunningPendingTask() {
        rerunCurrentlyRunningPendingTask = false
    }
}
