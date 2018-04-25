//
//  PendingTask+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/4/18.
//

import Foundation

public extension PendingTask {
    
    public func describe() -> String {
        let taskIdString: String = (self.taskId != nil) ? String(describing: self.taskId!) : "none"
        let dataIdString: String = (self.dataId != nil) ? String(describing: self.dataId!) : "none"
        let groupIdString: String = (self.groupId != nil) ? String(describing: self.groupId!) : "none"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss Z"
        let createdAtString: String = (self.createdAt != nil) ? dateFormatter.string(from: self.createdAt!) : "none"
        
        return "taskId: \(taskIdString) dataId: \(dataIdString) manuallyRun: \(self.manuallyRun) groupId: \(groupIdString) createdAt: \(createdAtString)"
    }

    public func addTaskStatusListenerForTask(listener: PendingTaskStatusListener) {
        if let taskId = self.taskId {
            WendyConfig.addTaskStatusListenerForTask(taskId, listener: listener)
        }
    }
    
    public func recordError(humanReadableErrorMessage: String?, errorId: String?) {
        let taskId = assertHasBeenAddedToWendy()
        Wendy.shared.recordError(taskId: taskId, humanReadableErrorMessage: humanReadableErrorMessage, errorId: errorId)
    }
    
    public func resolveError() {
        let taskId = assertHasBeenAddedToWendy()
        try Wendy.shared.resolveError(taskId: taskId)
    }
    
    public func getLatestError() -> PendingTaskError? {
        let taskId = assertHasBeenAddedToWendy()
        return Wendy.shared.getLatestError(taskId: taskId)
    }
    
    public func doesErrorExist() -> Bool {
        let taskId = assertHasBeenAddedToWendy()
        return Wendy.shared.doesErrorExist(taskId: taskId)
    }
    
    public func isAbleToManuallyRun() -> Bool {
        let taskId = assertHasBeenAddedToWendy()
        return Wendy.shared.isTaskAbleToManuallyRun(taskId)
    }
    
    public func hasBeenAddedToWendy() -> Bool {
        return self.taskId != nil
    }
    
    internal func assertHasBeenAddedToWendy() -> Double {
        if !hasBeenAddedToWendy() {
            Fatal.preconditionFailure("Cannot record error for your task because it has not been added to Wendy (aka: the task id has not been set yet)")
        }
    
        return self.taskId!
    }

}
