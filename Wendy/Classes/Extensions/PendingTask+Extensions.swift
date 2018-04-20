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
        
        return "taskId: \(taskIdString) dataId: \(dataIdString) manuallyRun: \(self.manuallyRun) groupId: \(groupIdString)"
    }

    public func addTaskStatusListenerForTask(listener: PendingTaskStatusListener) {
        if let taskId = self.taskId {
            WendyConfig.addTaskStatusListenerForTask(taskId, listener: listener)
        }
    }
    
    public func recordError(humanReadableErrorMessage: String?, errorId: String?) throws {
        let taskId = try assertHasBeenAddedToWendy()
        try Wendy.shared.recordError(taskId: taskId, humanReadableErrorMessage: humanReadableErrorMessage, errorId: errorId)
    }
    
    public func resolveError() throws {
        let taskId = try assertHasBeenAddedToWendy()
        try Wendy.shared.resolveError(taskId: taskId)
    }
    
    public func getLatestError() throws -> PendingTaskError? {
        let taskId = try assertHasBeenAddedToWendy()
        return try Wendy.shared.getLatestError(taskId: taskId)
    }
    
    public func doesErrorExist() throws -> Bool {
        let taskId = try assertHasBeenAddedToWendy()
        return try Wendy.shared.doesErrorExist(taskId: taskId)
    }
    
    public func isAbleToManuallyRun() throws -> Bool {
        let taskId = try assertHasBeenAddedToWendy()
        return try Wendy.shared.isTaskAbleToManuallyRun(taskId)
    }
    
    public func hasBeenAddedToWendy() -> Bool {
        return self.taskId != nil
    }
    
    internal func assertHasBeenAddedToWendy() throws -> Double {
        if !hasBeenAddedToWendy() {
            Fatal.preconditionFailure("Cannot record error for your task because it has not been added to Wendy (aka: the task id has not been set yet)")
        }
    
        return self.taskId!
    }

}
