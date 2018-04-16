//
//  PendingTaskError+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/16/18.
//

import Foundation

public extension PendingTaskError {
    
    public func describe() -> String {
        let errorIdString: String = (self.errorId != nil) ? String(describing: self.errorId!) : "none"
        let errorMessageString: String = (self.errorMessaage != nil) ? String(describing: self.errorMessaage!) : "none"
        
        return "errorId: \(errorIdString) errorMessage: \(errorMessageString) pendingTask: \(self.pendingTask.describe())"
    }
    
    public func resolveError() throws {
        try Wendy.shared.resolveError(taskId: self.pendingTask.taskId!)
    }
    
}
