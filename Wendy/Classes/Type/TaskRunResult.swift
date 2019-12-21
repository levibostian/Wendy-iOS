import Foundation

public enum TaskRunResult {
    case failure(error: Error)
    case successful
    case cancelled // Also counts if a task does not exist which means the task was cancelled.
    case skipped(reason: ReasonPendingTaskSkipped)
}
