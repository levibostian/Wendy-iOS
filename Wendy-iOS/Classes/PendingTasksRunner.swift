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

/**
 Requirements of the task runner:

 1. when you call `PendingTasks.runTask()` it returns instantly to you. It does *not* block the calling thread. It's like it schedules a job to run in the future.
 2. X number of threads all running the task runner's `runTask()` function can only run one at a time. (so, run runTask() in a sync way)
 3. The task runner's `runTask()` runs in a sync way (while the `PendingTask.runTask()` is async) where it does not return a result until the task has failed or succeeded. So, work in a blocking way.
 */
internal class PendingTasksRunner {
    
    internal static var sharedInstance: PendingTasksRunner = PendingTasksRunner()
    
    private init() {
    }
    
    fileprivate lazy var pendingTasksManager: PendingTasksManager = {
        return PendingTasksManager.sharedInstance
    }()

    internal var currentlyRunningTask: PendingTask?
    
    fileprivate let runPendingTasksDispatchQueue = DispatchQueue(label: "com.levibostian.wendy-ios.PendingTasksRunner.runPendingTasks")
    fileprivate let runPendingTasksDispatchGroup = DispatchGroup()
    fileprivate let runTaskDispatchQueue = DispatchQueue(label: "com.levibostian.wendy-ios.PendingTasksRunner.runTask")
    fileprivate let runTaskDispatchGroup = DispatchGroup()
    
    internal func runPendingTask(taskId: Double) {

        // ?????????? how do I return a pending task runner result from this function. ???

//        runTaskDispatchQueue.async(group: runTaskDispatchGroup) {
        runTaskDispatchQueue.async {
            self.runTaskDispatchGroup.enter()

            guard let persistedPendingTaskId: Double = try! self.pendingTasksManager.getTaskByTaskId(taskId)?.id else {
                // TODO return skipped task because task does not exist.
                self.runTaskDispatchGroup.leave()
                return // PendingTasksRunnerJobRunResult.taskDoesNotExist
            }
            let taskToRun: PendingTask = try! self.pendingTasksManager.getPendingTaskTaskById(taskId)!

            if !taskToRun.canRunTask() {
                WendyConfig.logTaskSkipped(taskToRun, reason: ReasonPendingTaskSkipped.notReadyToRun)
                LogUtil.d("Task: \(taskToRun.describe()) is not ready to run. Skipping it.")
                self.runTaskDispatchGroup.leave()
                return
            } else {
                self.currentlyRunningTask = taskToRun

                WendyConfig.logTaskRunning(taskToRun)
                LogUtil.d("Running task: \(taskToRun.describe())")
                taskToRun.runTask(complete: { (successful: Bool) in
                    if !successful {
                        LogUtil.d("Task: \(taskToRun.describe()) failed but will reschedule it. Skipping it.")
                        WendyConfig.logTaskComplete(taskToRun, successful: false)
                        self.runTaskDispatchGroup.leave()
                        return // successful result
                    }

                    LogUtil.d("Task: \(taskToRun.describe()) ran successful. Deleting it.")
                    WendyConfig.logTaskComplete(taskToRun, successful: true)
                    try! self.pendingTasksManager.deleteTask(taskId)
                    self.runTaskDispatchGroup.leave()
                    return // successful result.
                })
            }

            _ = self.runTaskDispatchGroup.wait(timeout: .distantFuture)
        }
    }

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

    fileprivate enum PendingTasksRunnerJobRunResult {
        case successful
        case notSuccessful
        case taskDoesNotExist
        case taskSkippedNotReady
    }

}
