import Foundation

public extension PendingTask {
    func describe() -> String {
        let taskIdString: String = (taskId != nil) ? String(describing: taskId!) : "none"
        let dataIdString: String = (dataId != nil) ? String(describing: dataId!) : "none"
        let groupIdString: String = (groupId != nil) ? String(describing: groupId!) : "none"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss Z"
        let createdAtString: String = (createdAt != nil) ? dateFormatter.string(from: createdAt!) : "none"

        return "taskId: \(taskIdString) dataId: \(dataIdString) manuallyRun: \(manuallyRun) groupId: \(groupIdString) createdAt: \(createdAtString)"
    }

    func addTaskStatusListenerForTask(listener: PendingTaskStatusListener) {
        if let taskId = self.taskId {
            WendyConfig.addTaskStatusListenerForTask(taskId, listener: listener)
        }
    }

    func recordError(humanReadableErrorMessage: String?, errorId: String?) {
        let taskId = assertHasBeenAddedToWendy()
        Wendy.shared.recordError(taskId: taskId, humanReadableErrorMessage: humanReadableErrorMessage, errorId: errorId)
    }

    func resolveError() {
        let taskId = assertHasBeenAddedToWendy()
        try Wendy.shared.resolveError(taskId: taskId)
    }

    func getLatestError() -> PendingTaskError? {
        let taskId = assertHasBeenAddedToWendy()
        return Wendy.shared.getLatestError(taskId: taskId)
    }

    func doesErrorExist() -> Bool {
        let taskId = assertHasBeenAddedToWendy()
        return Wendy.shared.doesErrorExist(taskId: taskId)
    }

    func isAbleToManuallyRun() -> Bool {
        let taskId = assertHasBeenAddedToWendy()
        return Wendy.shared.isTaskAbleToManuallyRun(taskId)
    }

    func hasBeenAddedToWendy() -> Bool {
        return taskId != nil
    }

    internal func assertHasBeenAddedToWendy() -> Double {
        if !hasBeenAddedToWendy() {
            Fatal.preconditionFailure("Cannot record error for your task because it has not been added to Wendy (aka: the task id has not been set yet)")
        }

        return taskId!
    }
}
