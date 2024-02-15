//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/13/24.
//

import Foundation
@testable import Wendy

class TaskRunnerListenerStub: TaskRunnerListener {
        
        var newTaskAddedCallCount = 0
        var runningTaskCallCount = 0
        var taskCompleteCallCount = 0
        var taskSkippedCallCount = 0
        var allTasksCompleteCallCount = 0
        
        func newTaskAdded(_ task: PendingTask) {
            newTaskAddedCallCount += 1
        }
        
        func runningTask(_ task: PendingTask) {
            runningTaskCallCount += 1
        }
        
        func taskComplete(_ task: PendingTask, successful: Bool, cancelled: Bool) {
            taskCompleteCallCount += 1
        }
        
        func taskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
            taskSkippedCallCount += 1
        }
        
        func allTasksComplete() {
            allTasksCompleteCallCount += 1
        }
}
