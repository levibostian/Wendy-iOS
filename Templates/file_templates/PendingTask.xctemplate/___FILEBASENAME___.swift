import Foundation
import Wendy

class ___FILEBASENAMEASIDENTIFIER___: PendingTask {
    static let pendingTaskRunnerTag = String(describing: ___FILEBASENAMEASIDENTIFIER___.self)

    var taskId: Double?
    var dataId: String?
    var groupId: String?
    var tag: String = ___FILEBASENAMEASIDENTIFIER___.pendingTaskRunnerTag
    var manuallyRun: Bool = false

    convenience init(dataId: String) {
        self.init()
        self.dataId = dataId
    }

    func canRunTask() -> Bool {
        return true
    }

    func runTask(complete: @escaping (Bool) -> Void) {
        // TODO:
    }
}
