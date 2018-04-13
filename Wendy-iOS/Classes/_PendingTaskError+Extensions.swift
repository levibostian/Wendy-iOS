//
//  _PendingTaskError+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/13/18.
//

import Foundation

extension PendingTaskError {
    
    internal convenience init(from: PersistedPendingTaskError, pendingTask: PendingTask) {
        self.init(pendingTask: pendingTask, errorId: from.errorId, errorMessage: from.errorMessage, createdAt: from.createdAt!)
    }
    
    public func describe() -> String {
        let errorIdString: String = (self.errorId != nil) ? String(describing: self.errorId!) : "none"
        let errorMessageString: String = (self.errorMessaage != nil) ? String(describing: self.errorMessaage!) : "none"
        
        return "errorId: \(errorIdString) errorMessage: \(errorMessageString) pendingTask: \(self.pendingTask.describe())"
    }
    
}
