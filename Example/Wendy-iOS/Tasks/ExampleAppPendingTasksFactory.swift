//
//  ExampleAppPendingTasksFactory.swift
//  Wendy-iOS_Example
//
//  Created by Levi Bostian on 3/30/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Wendy

class ExampleAppPendingTasksFactory: PendingTasksFactory {

    func getTask(tag: String) -> PendingTask {
        switch tag {
        case AddGroceryListItemPendingTask.pendingTaskRunnerTag:
            return AddGroceryListItemPendingTask()
        default:
            fatalError("Cannot find task for tag: \(tag)")
        }
    }

}
