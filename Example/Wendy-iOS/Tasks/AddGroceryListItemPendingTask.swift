//
//  FooPendingTask.swift
//  Wendy-iOS_Example
//
//  Created by Levi Bostian on 3/26/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation

class AddGroceryListItemPendingTask: PendingTasksTaskRunner {

    static let pendingTaskRunnerTag = String(describing: AddGroceryListItemPendingTask.self)

    var dataId: String?
    var groupId: String?
    var pendingTaskRunnerTag: String = AddGroceryListItemPendingTask.pendingTaskRunnerTag

    convenience init(groceryListItemName: String) {
        self.init()
        self.dataId = groceryListItemName
    }

    class func runTask(dataId: String?, complete: @escaping (Bool) -> Void) {
        complete(true)
    }

}
