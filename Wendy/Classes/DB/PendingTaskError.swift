import Foundation

public class PendingTaskError {
    public let pendingTask: PendingTask!
    public let createdAt: Date?
    public let errorId: String?
    public let errorMessage: String?

    internal init(pendingTask: PendingTask, errorId: String?, errorMessage: String?, createdAt: Date) {
        self.pendingTask = pendingTask
        self.errorId = errorId
        self.errorMessage = errorMessage
        self.createdAt = createdAt
    }
}
