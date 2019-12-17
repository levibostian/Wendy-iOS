//
//  ReasonPendingTaskSkipped.swift
//  Wendy
//
//  Created by Levi Bostian on 4/2/18.
//

import Foundation

public enum ReasonPendingTaskSkipped {
    case cancelled
    case notReadyToRun
    case partOfFailedGroup
    case unresolvedRecordedError
}
