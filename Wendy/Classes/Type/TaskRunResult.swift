//
//  TaskRunResult.swift
//  Wendy
//
//  Created by Levi Bostian on 12/21/19.
//

import Foundation

public enum TaskRunResult {
    case failure(error: Error)
    case successful
    case skipped(reason: ReasonPendingTaskSkipped)
}
