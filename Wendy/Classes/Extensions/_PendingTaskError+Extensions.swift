//
//  _PendingTaskError+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/13/18.
//

import Foundation

internal extension PendingTaskError {
    
    internal convenience init(from: PersistedPendingTaskError, pendingTask: PendingTask) {
        self.init(pendingTask: pendingTask, errorId: from.errorId, errorMessage: from.errorMessage, createdAt: from.createdAt!)
    }
    
}
