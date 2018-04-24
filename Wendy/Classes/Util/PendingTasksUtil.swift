//
//  PendingTasksUtil.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/9/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation

internal class PendingTasksUtil {
    
    private static let prefix = "pendingTasks_"
    private static let pendingTasksNextPendingTaskIdKey = "\(prefix)pendingTasksNextPendingTaskIdKey"
    private static let rerunCurrentlyRunningPendingTaskKey = "\(prefix)rerunCurrentlyRunningPendingTaskKey"
    
    internal class func getNextPendingTaskId() -> Double {
        let nextPendingTaskId = UserDefaults.standard.double(forKey: pendingTasksNextPendingTaskIdKey) + 1
        UserDefaults.standard.set(nextPendingTaskId, forKey: pendingTasksNextPendingTaskIdKey)
        return nextPendingTaskId
    }
    
    internal static var rerunCurrentlyRunningPendingTask: Bool {
        get {
            return UserDefaults.standard.double(forKey: rerunCurrentlyRunningPendingTaskKey) > 0
        }
        set {
            if newValue {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: rerunCurrentlyRunningPendingTaskKey)
            } else {
                UserDefaults.standard.set(0, forKey: rerunCurrentlyRunningPendingTaskKey)
            }
        }
    }
    
    internal class func getRerunCurrentlyRunningPendingTaskTime() -> Date? {
        guard let timeInternal: Double = UserDefaults.standard.double(forKey: rerunCurrentlyRunningPendingTaskKey), timeInternal > 0 else {
            return nil
        }
        
        return Date(timeIntervalSince1970: timeInternal)
    }
    
    internal class func resetRerunCurrentlyRunningPendingTask() {
        self.rerunCurrentlyRunningPendingTask = false
    }
    
}
