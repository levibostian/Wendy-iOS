//
//  PendingTask.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/9/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation
import CoreData

internal extension PersistedPendingTask {

    internal convenience init() {
        // This exists so when children of PendingTask initialize pending tasks with self.init(), we are automatically setting the CoreData context. We don't want the developer to even realize we are using CoreData here so we are hiding this.
        let managedContext = CoreDataManager.shared.viewContext
        self.init(entity: NSEntityDescription.entity(forEntityName: "PersistedPendingTask", in: managedContext)!, insertInto: managedContext)
    }
    
    internal var pendingTask: PendingTask {
        get {
            var blankPendingTask = Wendy.shared.pendingTasksFactory.getTaskAssertPopulated(tag: self.tag!)
            blankPendingTask.populate(from: self)
            return blankPendingTask
        }
    }

    internal convenience init(pendingTask: PendingTask) {
        self.init()
        self.dataId = pendingTask.dataId
        self.groupId = pendingTask.groupId
        self.tag = pendingTask.tag
        self.manuallyRun = pendingTask.manuallyRun
        self.createdAt = Date() // Very important. This determines the sort order of when tasks run by the task runner. createdAt needs to be set by Wendy internally and only modified by Wendy under certain circumstances.

        self.id = PendingTasksUtil.getNextPendingTaskId()
    }
    
    // Using instead of Equatable protocol because Swift does not allow a protocol inherit another protocol *and* I don't want the subclass to inherit Equatable, I just want to internally.
    internal func equals(_ other: PersistedPendingTask) -> Bool {
        return self.tag == other.tag &&
            self.dataId == other.dataId
    }

}
