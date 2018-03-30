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

    convenience init(groceryListItemName: String) {
        self.init()
        self.dataId = groceryListItemName
    }

    func canRunTask() -> Bool {
        return true
    }

    func runTask(complete: @escaping (Bool) -> Void) {
        complete(false)
    }

}

