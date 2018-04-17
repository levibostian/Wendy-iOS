//
//  FooPendingTask.swift
//  Wendy-iOS_Example
//
//  Created by Levi Bostian on 3/26/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Wendy

class AddGroceryListItemPendingTask: PendingTask {

    static let pendingTaskRunnerTag = String(describing: AddGroceryListItemPendingTask.self)

    var taskId: Double?
    var dataId: String?
    var groupId: String?
    var tag: String = AddGroceryListItemPendingTask.pendingTaskRunnerTag
    var manuallyRun: Bool = false
    var createdAt: Date?

    convenience init(groceryListItemName: String) {
        self.init()
        self.dataId = groceryListItemName
    }

    func isReadyToRun() -> Bool {
        let canRunTask = drand48() > 0.5
        return canRunTask
    }

    func runTask(complete: @escaping (Bool) -> Void) {
        sleep(2)

        let successful = drand48() > 0.5
        complete(successful)
    }

}
