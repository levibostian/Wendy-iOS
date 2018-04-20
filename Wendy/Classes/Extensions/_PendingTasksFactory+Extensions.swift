//
//  _PendingTasksFactory+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/4/18.
//

import Foundation
import Require

internal extension PendingTasksFactory {

    internal func getTaskAssertPopulated(tag: String) -> PendingTask {
        return self.getTask(tag: tag).require(hint: "You forgot to add \(tag) to your \(String(describing: PendingTasksFactory.self))")
    }

}
