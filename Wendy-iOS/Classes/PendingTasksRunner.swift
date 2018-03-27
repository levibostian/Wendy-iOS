//
//  PendingTasksRunner.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/9/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation

public struct PendingTasksRunnerResult {
    var numberTasksRun: Int
    var numberSuccessfulTasks: Int
    var numberFailedTasks: Int
    
    init() {
        numberTasksRun = 0
        numberSuccessfulTasks = 0
        numberFailedTasks = 0
    }
    
    mutating func addSuccessfulTask() {
        self.numberTasksRun += 1
        self.numberSuccessfulTasks += 1
    }
    
    mutating func addFailedTask() {
        self.numberTasksRun += 1
        self.numberFailedTasks += 1
    }
}

internal class PendingTasksRunner {
    
    internal static var sharedInstance: PendingTasksRunner = PendingTasksRunner()
    
    private init() {
    }
    
    fileprivate var pendingTasksManager: PendingTasksManager = PendingTasksManager.sharedInstance
    
    fileprivate let runPendingTasksDispatchQueue = DispatchQueue(label: "com.levibostian.wendy-ios.PendingTasksRunner.runPendingTasks")
    fileprivate let runPendingTasksDispatchGroup = DispatchGroup()
    fileprivate let runTaskDispatchQueue = DispatchQueue(label: "com.levibostian.wendy-ios.PendingTasksRunner.runTask")
    fileprivate let runTaskDispatchGroup = DispatchGroup()
    
//    internal func runPendingTask(taskId: Double, complete: @escaping PendingTasks.PendingTasksOnCompleteListener, onError: @escaping PendingTasks.PendingTasksOnErrorListener) {
//        runTaskDispatchQueue.async {
//            self.runTaskDispatchGroup.enter()
//
//            // Variables here so they do not get garbage collected.
//            let pendingTaskById: PendingTask?
//            do {
//                pendingTaskById = try self.pendingTasksManager.getTaskById(taskId)
//            } catch let error {
//                onError(error)
//                self.runTaskDispatchGroup.leave()
//                return
//            }
//
//            if pendingTaskById == nil {
//                onError(PendingTasksError.taskDoesNotExist(taskId: taskId))
//                self.runTaskDispatchGroup.leave()
//                return
//            }
//
//            PendingTasks.sharedInstance.pendingTasksFactory!.runTask(pendingTaskRunnerTag: pendingTaskById!.tag, dataId: pendingTaskById?.dataId, complete: { (successful: Bool) in
//                if successful {
//                    self.pendingTasksManager.deleteTask(pendingTaskById!)
//                }
//
//                var result = PendingTasksRunnerResult()
//                successful ? result.addSuccessfulTask() : result.addFailedTask()
//                complete(result)
//                self.runTaskDispatchGroup.leave()
//            })
//
//            _ = self.runTaskDispatchGroup.wait(timeout: .distantFuture)
//        }
//    }
//
//    internal func runPendingTasks(complete: @escaping PendingTasks.PendingTasksOnCompleteListener, onError: @escaping PendingTasks.PendingTasksOnErrorListener) {
//        runPendingTasksDispatchQueue.async {
//            self.runPendingTasksDispatchGroup.enter()
//            // Run async code in here. Once entered into the dispatch group, we are safe.
//            var runningTasksResult = PendingTasksRunnerResult()
//            var lastSuccessfulOrFailedTaskId: Double = 0
//            var failedTasksGroups: [String] = []
//
//            // Variables here so they do not get garbage collected.
//            var nextTaskToRun: PendingTask?
//            var nextTaskToRunRunner: PendingTasksTaskRunner?
//
//            func runNextTask() {
//                do {
//                    nextTaskToRun = try self.pendingTasksManager.getNextTask(lastSuccessfulOrFailedTaskId, failedTasksGroups: failedTasksGroups)
//                } catch let error {
//                    onError(error)
//                    self.runPendingTasksDispatchGroup.leave()
//                    return
//                }
//
//                if nextTaskToRun == nil {
//                    complete(runningTasksResult)
//                    self.runPendingTasksDispatchGroup.leave()
//                    return
//                }
//
//                PendingTasks.sharedInstance.pendingTasksFactory!.runTask(pendingTaskRunnerTag: nextTaskToRun!.tag, dataId: nextTaskToRun?.dataId, complete: { (successful: Bool) in
//                    lastSuccessfulOrFailedTaskId = nextTaskToRun!.id
//                    if successful {
//                        runningTasksResult.addSuccessfulTask()
//                        self.pendingTasksManager.deleteTask(nextTaskToRun!)
//                    } else {
//                        if let nextTaskGroupId = nextTaskToRun!.groupId {
//                            failedTasksGroups.append(nextTaskGroupId)
//                        }
//                        runningTasksResult.addFailedTask()
//                    }
//
//                    return runNextTask()
//                })
//            }
//
//            runNextTask()
//            _ = self.runPendingTasksDispatchGroup.wait(timeout: .distantFuture)
//        }
//    }

}
