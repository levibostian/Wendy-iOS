import Foundation

internal extension PendingTaskError {
    convenience init(from: PersistedPendingTaskError, pendingTask: PendingTask) {
        self.init(pendingTask: pendingTask, errorId: from.errorId, errorMessage: from.errorMessage, createdAt: from.createdAt!)
    }
}
