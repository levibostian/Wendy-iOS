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
        self.createdAt = from.createdAt!
    }
    
    // Using instead of Equatable protocol because Swift does not allow a protocol inherit another protocol *and* I don't want the subclass to inherit Equatable, I just want to internally.
    internal func equals(_ other: PendingTask) -> Bool {
        return self.tag == other.tag &&
            self.dataId == other.dataId
    }

}
