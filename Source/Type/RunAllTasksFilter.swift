import Foundation

/**
 Note: This is *only* used for filtering of running all tasks.
 */
public enum RunAllTasksFilter: Sendable {
    case group(id: String)
}
