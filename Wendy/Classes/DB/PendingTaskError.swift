//
//  PendingTaskError.swift
//  Wendy
//
//  Created by Levi Bostian on 4/13/18.
//

import Foundation

public class PendingTaskError {
    
    let pendingTask: PendingTask!
    let createdAt: Date?
    let errorId: String?
    let errorMessage: String?
    
    internal init(pendingTask: PendingTask, errorId: String?, errorMessage: String?, createdAt: Date) {
        self.pendingTask = pendingTask
        self.errorId = errorId
        self.errorMessage = errorMessage
        self.createdAt = nil
    }
    
}
