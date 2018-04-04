//
//  PendingTask+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/4/18.
//

import Foundation

public extension PendingTask {

    public func addTaskStatusListenerForTask(listener: PendingTaskStatusListener) {
        if let taskId = self.taskId {
            WendyConfig.addTaskStatusListenerForTask(taskId, listener: listener)
        }
    }

}
