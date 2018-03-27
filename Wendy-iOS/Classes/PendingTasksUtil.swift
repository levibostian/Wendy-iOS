//
//  _PendingTasks.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/9/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation

internal class PendingTasksUtil {
    
    internal static let pendingTasksNextPendingTaskIdKey = "pendingTasksk_pendingTasksNextPendingTaskIdKey"
    
    internal class func getNextPendingTaskId() -> Double {
        let nextPendingTaskId = UserDefaults.standard.double(forKey: pendingTasksNextPendingTaskIdKey) + 1
        UserDefaults.standard.set(nextPendingTaskId, forKey: pendingTasksNextPendingTaskIdKey)
        return nextPendingTaskId
    }    
    
}
