//
//  PendingTask+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 3/30/18.
//

import Foundation

internal extension PendingTask {

    internal mutating func populate(from: PersistedPendingTask) {
        self.taskId = from.id
        self.dataId = from.dataId
        self.manuallyRun = from.manuallyRun
        self.groupId = from.groupId
    }

}
