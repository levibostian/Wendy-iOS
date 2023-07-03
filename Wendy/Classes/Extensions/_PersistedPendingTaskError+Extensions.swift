import CoreData
import Foundation

internal extension PersistedPendingTaskError {
    convenience init() {
        let managedContext = CoreDataManager.shared.privateContext
        self.init(entity: NSEntityDescription.entity(forEntityName: "PersistedPendingTaskError", in: managedContext)!, insertInto: managedContext)
    }

    convenience init(errorMessage: String?, errorId: String?, persistedPendingTask: PersistedPendingTask) {
        self.init()
        self.pendingTask = persistedPendingTask
        self.errorId = errorId
        self.errorMessage = errorMessage
        self.createdAt = Date()
    }
}
