import Foundation
import Require

internal extension PendingTasksFactory {
    func getTaskAssertPopulated(tag: String) -> PendingTask {
        return getTask(tag: tag).require(hint: "You forgot to add \(tag) to your \(String(describing: PendingTasksFactory.self))")
    }
}
