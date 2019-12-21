import Foundation

/**
 Note: This is *only* used for filtering of running all tasks.
 */
public enum RunAllTasksFilter {
    case group(id: String)
    case collection(id: CollectionId)
}
