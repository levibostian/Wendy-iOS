//
//  PendingTaskError+Testing.swift
//  Wendy
//
//  Created by Levi Bostian on 12/23/19.
//

import Foundation

public extension PendingTaskError {
    static var testing: Testing {
        return Testing()
    }

    class Testing {
        public func get(pendingTask: PendingTask, errorId: String, errorMessage: String, createdAt: Date) -> PendingTaskError {
            return PendingTaskError(pendingTask: pendingTask, errorId: errorId, errorMessage: errorMessage, createdAt: createdAt)
        }
    }
}
