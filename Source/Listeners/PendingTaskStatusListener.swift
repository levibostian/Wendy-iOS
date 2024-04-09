import Foundation

public protocol PendingTaskStatusListener: AnyObject {
    func running(taskId: Double)
    func complete(taskId: Double, successful: Bool, cancelled: Bool)
    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped)
}

struct WeakReferencePendingTaskStatusListener {
    weak var listener: PendingTaskStatusListener?
}
