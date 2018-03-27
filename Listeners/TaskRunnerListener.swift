//
//  TaskRunnerListener.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 3/27/18.
//

import Foundation

public protocol TaskRunnerListener {

    func newTaskAdded(_ task: PendingTask)

}

internal struct WeakReferenceTaskRunnerListener {
    weak var taskRunner: TaskRunnerListener
}
