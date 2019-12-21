//
//  FooPendingTask.swift
//  Wendy-iOS_Example
//
//  Created by Levi Bostian on 3/26/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Wendy

enum AddGroceryListItemPendingTaskError: Error {
    case randomError
}
// optional below
extension AddGroceryListItemPendingTaskError: LocalizedError {
    var errorDescription: String? {
        return localizedDescription
    }
    var localizedDescription: String {
        switch self {
        case .randomError: return "Random error message here"
        }
    }
}

class AddGroceryListItemPendingTask: PendingTask {

    static let pendingTaskRunnerTag = String(describing: AddGroceryListItemPendingTask.self)

    var taskId: Double?
    var dataId: String?
    var groupId: String?
    var tag: String = AddGroceryListItemPendingTask.pendingTaskRunnerTag
    var manuallyRun: Bool = false
    var createdAt: Date?

    convenience init(groceryListItemName: String, manuallyRun: Bool, groupId: String?) {
        self.init()
        self.dataId = groceryListItemName
        self.manuallyRun = manuallyRun
        self.groupId = groupId
    }

    func isReadyToRun() -> Bool {
        let canRunTask = drand48() > 0.2
        return canRunTask
    }

    func runTask(complete: @escaping (Error?) -> Void) {
        sleep(2)

        let successful = drand48() > 0.5
        let humanError = drand48() > 0.5
        if !successful && humanError {
            Wendy.shared.recordError(taskId: self.taskId!, humanReadableErrorMessage: "Random error message here", errorId: nil)
        }
        
        let result: Error? = successful ? nil : AddGroceryListItemPendingTaskError.randomError
        complete(result)
    }

}
