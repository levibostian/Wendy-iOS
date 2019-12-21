import Foundation

public protocol PendingTask {
    typealias Tag = String

    static var tag: Tag { get }

    var taskId: Double? { get set } // Simply links a PendingTask to a PersistedPendingTask. This identifies a PendingTask. It is *not* used as the sort order for when tasks will be run.
    var dataId: String? { get set }
    var manuallyRun: Bool { get set }
    var groupId: String? { get set }
    var createdAt: Date? { get set } // How the order is determined by the task runner. Just like taskId, this is nil until the PendingTask is added to Wendy.

    func runTask(complete: @escaping (Error?) -> Void)
    func isReadyToRun() -> Bool
}

public extension PendingTask {
    var tag: Tag {
        return Self.tag
    }
}
