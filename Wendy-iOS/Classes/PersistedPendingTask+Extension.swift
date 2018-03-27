//
//  PendingTask.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/9/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation
import CoreData

public protocol PendingTasksTaskRunner {
    static func runTask(dataId: String?, complete: @escaping (_ successful: Bool) -> Void)
    var dataId: String? { get set }
    var pendingTaskRunnerTag: String { get set }
    var groupId: String? { get set }
}

internal extension PersistedPendingTask {
    
    convenience init() {
        // This exists so when children of PendingTask initialize pending tasks with self.init(), we are automatically setting the CoreData context. We don't want the developer to even realize we are using CoreData here so we are hiding this.
        let managedContext = CoreDataManager.sharedInstance.viewContext 
        self.init(entity: NSEntityDescription.entity(forEntityName: "PersistedPendingTask", in: managedContext)!, insertInto: managedContext)
    }
    
    convenience init(pendingTask: PendingTask) {
        self.init()
        self.dataId = pendingTask.dataId
        self.groupId = pendingTask.groupId
        self.tag = pendingTask.tag
        self.manuallyRun = pendingTask.manuallyRun
        self.createdAt = Date()
        
        self.id = PendingTasksUtil.getNextPendingTaskId()
    }
    
}
