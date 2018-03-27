//
//  WendyConfig.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 3/27/18.
//

import Foundation

public class WendyConfig {

    fileprivate static var taskRunnerListeners: [WeakReferenceTaskRunnerListener] = []

    public class func addTaskRunnerListener(_ listener: TaskRunnerListener) {
        taskRunnerListeners.append(WeakReferenceTaskRunnerListener(taskRunner: listener))
    }

}

internal extension WendyConfig {

    internal class func logNewTaskAdded(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.taskRunner.newTaskAdded(task)
            })
        }
    }

}
