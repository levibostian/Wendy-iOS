import Foundation
import Wendy

import Wendy

class ___FILEBASENAMEASIDENTIFIER___: PendingTasksFactory {
    func getTask(tag: String) -> PendingTask? {
        switch tag {
        case NameOfPendingTask.pendingTaskRunnerTag:
            return NameOfPendingTask()
        default:
            return nil
        }
    }
}
