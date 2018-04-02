//
//  PendingTask+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 3/30/18.
//

import Foundation

extension PendingTask {

    internal mutating func populate(from: PersistedPendingTask) {
        self.taskId = from.id
        self.dataId = from.dataId
        self.manuallyRun = from.manuallyRun
        self.groupId = from.groupId
    }

    public func describe() -> String {
        let taskIdString: String = (self.taskId != nil) ? String(describing: self.taskId!) : "none"
        let dataIdString: String = (self.dataId != nil) ? String(describing: self.dataId!) : "none"
        let groupIdString: String = (self.groupId != nil) ? String(describing: self.groupId!) : "none"

        return "taskId: \(taskIdString) dataId: \(dataIdString) manuallyRun: \(self.manuallyRun) groupId: \(groupIdString)"
    }

}
