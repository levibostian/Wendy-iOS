import Foundation

public protocol TaskRunnerListener: AnyObject {
    func newTaskAdded(_ task: PendingTask)

    func runningTask(_ task: PendingTask)

    func taskComplete(_ task: PendingTask, successful: Bool, cancelled: Bool)
    func taskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped)

    func allTasksComplete()
}

struct WeakReferenceTaskRunnerListener {
    weak var listener: TaskRunnerListener!
}
