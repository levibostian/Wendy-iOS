//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

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
