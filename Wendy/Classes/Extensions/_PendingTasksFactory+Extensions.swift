//
//  _PendingTasksFactory+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/4/18.
//

import Foundation

internal extension PendingTasksFactory {

    internal func getTaskAssertPopulated(tag: String) -> PendingTask {
        guard let pendingTask = try self.getTask(tag: tag) else {
            fatalError("You forgot to add \(tag) to your \(String(describing: PendingTasksFactory.self))")
        }
        return pendingTask
    }

}
