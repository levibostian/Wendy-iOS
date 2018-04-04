//
//  TaskRunnerListener.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 3/27/18.
//

import Foundation

public protocol TaskRunnerListener: AnyObject {
    func newTaskAdded(_ task: PendingTask)
    func taskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped)
    func taskComplete(_ task: PendingTask, successful: Bool)
    func runningTask(_ task: PendingTask)
    func allTasksComplete()
}

internal struct WeakReferenceTaskRunnerListener {
    weak var taskRunner: TaskRunnerListener!
}
