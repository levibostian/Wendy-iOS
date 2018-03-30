//
//  PendingTask+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 3/30/18.
//

import Foundation

extension PendingTask {

    internal mutating func populate(from: PersistedPendingTask) {
        self.dataId = from.dataId
        self.manuallyRun = from.manuallyRun
        self.groupId = from.groupId
    }

}
