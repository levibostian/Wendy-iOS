import Foundation

/**
 Tasks that were skipped and will run again at some time in the future.
 */
public enum ReasonPendingTaskSkipped: Sendable {
    case partOfFailedGroup
}
