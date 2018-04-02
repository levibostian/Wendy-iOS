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

    public static var debug: Bool = true

}

internal extension WendyConfig {

    internal class func logNewTaskAdded(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.taskRunner.newTaskAdded(task)
            })
        }
    }

    internal class func logTaskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.taskRunner.taskSkipped(task, reason: reason)
            })
        }
    }

    internal class func logTaskComplete(_ task: PendingTask, successful: Bool) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.taskRunner.taskComplete(task, successful: successful)
            })
        }
    }

    internal class func logTaskRunning(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.taskRunner.runningTask(task)
            })
        }
    }

}
