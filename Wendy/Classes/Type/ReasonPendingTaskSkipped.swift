import Foundation

/**
 Tasks that were skipped and will run again at some time in the future.
 */
public enum ReasonPendingTaskSkipped {
    case notReadyToRun
    case partOfFailedGroup
    case unresolvedRecordedError(unresolvedError: PendingTaskError)
}
