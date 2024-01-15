//
//  MyWendyTaskRunner.swift
//  Wendy_Example
//
//  Created by Levi Bostian on 1/14/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import Wendy

class MyWendyTaskRunner: WendyTaskRunner {
    func runTask(tag: String, dataId: String?, complete: @escaping (Error?) -> Void) {
        let taskType = TaskTag(rawValue: tag)!
        
        switch taskType {
        case .addGroceryListItem:
            sleep(2)

            let successful = drand48() > 0.5

            let result: Error? = successful ? nil : AddGroceryListItemPendingTaskError.randomError
            
            complete(result)
            
            break
        }
    }
}

