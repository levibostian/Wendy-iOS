//
//  PendingTaskStatusListener.swift
//  Wendy
//
//  Created by Levi Bostian on 4/4/18.
//

import Foundation

public protocol PendingTaskStatusListener: AnyObject {
    func running(taskId: Double)
    func complete(taskId: Double, successful: Bool)
    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped)
    func errorRecorded(taskId: Double, errorMessage: String?, errorId: String?)
    func errorResolved(taskId: Double)
}

internal struct WeakReferencePendingTaskStatusListener {
    weak var listener: PendingTaskStatusListener?
}
