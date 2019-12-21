//
//  ReasonPendingTaskSkipped.swift
//  Wendy
//
//  Created by Levi Bostian on 4/2/18.
//

import Foundation

public enum ReasonPendingTaskSkipped {
    case cancelled // Also counts if a task does not exist which means the task was cancelled.
    case notReadyToRun
    case partOfFailedGroup
    case unresolvedRecordedError(unresolvedError: PendingTaskError)
}
