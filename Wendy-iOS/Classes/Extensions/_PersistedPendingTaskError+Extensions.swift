//
//  _PersistedPendingTaskError+Extensions.swift
//  Wendy
//
//  Created by Levi Bostian on 4/13/18.
//

import Foundation
import CoreData

internal extension PersistedPendingTaskError {
    
    internal convenience init() {
        let managedContext = CoreDataManager.sharedInstance.viewContext
        self.init(entity: NSEntityDescription.entity(forEntityName: "PersistedPendingTaskError", in: managedContext)!, insertInto: managedContext)
    }
    
    internal convenience init(errorMessage: String?, errorId: String?, persistedPendingTask: PersistedPendingTask) {
        self.init()
        self.pendingTask = persistedPendingTask
        self.errorId = errorId
        self.errorMessage = errorMessage
        self.createdAt = Date()
    }
    
}
