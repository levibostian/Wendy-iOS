import Foundation
@testable import Wendy

class PendingTaskStatusListenerStub: PendingTaskStatusListener {
    var runningTaskId: Double?
    var completeTaskId: Double?
    var completeSuccessful: Bool?
    var completeCancelled: Bool?
    var skippedTaskId: Double?
    var skippedReason: ReasonPendingTaskSkipped?

    func running(taskId: Double) {
        runningTaskId = taskId
    }

    func complete(taskId: Double, successful: Bool, cancelled: Bool) {
        completeTaskId = taskId
        completeSuccessful = successful
        completeCancelled = cancelled
    }

    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped) {
        skippedTaskId = taskId
        skippedReason = reason
    }
}
