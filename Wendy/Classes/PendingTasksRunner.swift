//
//  PendingTasksRunner.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/9/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation

public struct PendingTasksRunnerResult {
    let numberTasksRun: Int
    let numberSuccessfulTasks: Int
    let numberFailedTasks: Int
    
    init() {
        numberTasksRun = 0
        numberSuccessfulTasks = 0
        numberFailedTasks = 0
    }
    
    init(numberSuccessfulTasks: Int, numberFailedTasks: Int) {
        self.numberTasksRun = numberSuccessfulTasks + numberFailedTasks
        self.numberSuccessfulTasks = numberSuccessfulTasks
        self.numberFailedTasks = numberFailedTasks
    }
    
    func addSuccessfulTask() -> PendingTasksRunnerResult {
        return PendingTasksRunnerResult(numberSuccessfulTasks: numberSuccessfulTasks + 1, numberFailedTasks: numberFailedTasks)
    }
    
    func addFailedTask() -> PendingTasksRunnerResult {
        return PendingTasksRunnerResult(numberSuccessfulTasks: numberSuccessfulTasks, numberFailedTasks: numberFailedTasks + 1)
    }
}

/**
 Requirements of the task runner:
 
 1. when you call `Wendy.runTask()` it returns instantly to you. It does *not* block the calling thread. It's like it schedules a job to run in the future.
 2. X number of threads all running the task runner's `runTask()` function can only run one at a time. (so, run runTask() in a sync way)
 3. The task runner's `runTask()` runs in a sync way (while the `PendingTask.runTask()` is async) where it does not return a result until the task has failed or succeeded. So, work in a blocking way.
 */
internal class PendingTasksRunner {
    
    internal static var shared: PendingTasksRunner = PendingTasksRunner()
    
    private init() {
    }
    
    fileprivate var lastSuccessfulOrFailedTaskId: Double = 0
    fileprivate var failedTasksGroups: [String] = []
    internal var currentlyRunningTask: PendingTask?
    
    // I created a separate class for running a single pending task simply as a wrapper to the function runPendingTask(taskId).
    // this function is very important to have it run in a synchronized way and to enforce that, I need to make sure it uses a DispatchQueue to run all of it's callers requests. So, I created this class to make sure I don't make the mistake of accidently calling this `runPendingTask(taskId)` function inside of the `PendingTasksRunner` without following my rule of *this function must run in a synchonized way!* (I already made this mistake....)
    fileprivate class RunSinglePendingTaskRunner {
        
        static let shared = RunSinglePendingTaskRunner()
        
        private let runPendingTaskDispatchQueue = DispatchQueue(label: "com.levibostian.wendy.PendingTasksRunner.Scheduler.runPendingTask")
        private let runTaskDispatchGroup = DispatchGroup()
        
        private init() {
        }
        
        fileprivate func scheduleRunPendingTask(_ taskId: Double) {
            runPendingTaskDispatchQueue.async {
                self.runPendingTask(taskId: taskId)
            }
        }
        
        fileprivate func runPendingTaskWait(_ taskId: Double) -> PendingTasksRunnerJobRunResult {
            return runPendingTaskDispatchQueue.sync { () -> PendingTasksRunnerJobRunResult in
                return self.runPendingTask(taskId: taskId)
            }
        }
        
        /**
         * @throws when in [WendyConfig.strict] mode and you say that your [PendingTask] was [PendingTaskResult.SUCCESSFUL] when you have an unresolved error recorded for that [PendingTask].
         */
        private func runPendingTask(taskId: Double) -> PendingTasksRunnerJobRunResult {
            self.runTaskDispatchGroup.enter()
            var runTaskResult: PendingTasksRunnerJobRunResult!
            
            guard let persistedPendingTaskId: Double = try! PendingTasksManager.shared.getTaskByTaskId(taskId)?.id else {
                runTaskResult = PendingTasksRunnerJobRunResult.taskDoesNotExist
                
                self.runTaskDispatchGroup.leave()
                return runTaskResult // This code should *not* be executed because of .leave() above.
            }
            let taskToRun: PendingTask = try! PendingTasksManager.shared.getPendingTaskTaskById(taskId)!
            
            if !taskToRun.isReadyToRun() {
                WendyConfig.logTaskSkipped(taskToRun, reason: ReasonPendingTaskSkipped.notReadyToRun)
                LogUtil.d("Task: \(taskToRun.describe()) is not ready to run. Skipping it.")
                runTaskResult = PendingTasksRunnerJobRunResult.taskSkippedNotReady
                
                self.runTaskDispatchGroup.leave()
                return runTaskResult // This code should *not* be executed because of .leave() above.
            }
            if let _ = try! PendingTasksManager.shared.getLatestError(pendingTaskId: taskToRun.taskId!) {
                WendyConfig.logTaskSkipped(taskToRun, reason: ReasonPendingTaskSkipped.unresolvedRecordedError)
                LogUtil.d("Task: \(taskToRun.describe()) has a unresolved error recorded. Skipping it.")
                runTaskResult = PendingTasksRunnerJobRunResult.skippedUnresolvedRecordedError
                
                self.runTaskDispatchGroup.leave()
                return runTaskResult // This code should *not* be executed because of .leave() above.
            }
            
            PendingTasksUtil.resetRerunCurrentlyRunningPendingTask()
            PendingTasksRunner.shared.currentlyRunningTask = taskToRun
            
            WendyConfig.logTaskRunning(taskToRun)
            LogUtil.d("Running task: \(taskToRun.describe())")
            taskToRun.runTask(complete: { (successful: Bool) in
                PendingTasksRunner.shared.currentlyRunningTask = nil
                
                if !successful {
                    LogUtil.d("Task: \(taskToRun.describe()) failed but will reschedule it. Skipping it.")
                    WendyConfig.logTaskComplete(taskToRun, successful: successful)
                    runTaskResult = PendingTasksRunnerJobRunResult.notSuccessful
                    
                    self.runTaskDispatchGroup.leave()
                    return
                }
                
                if try! Wendy.shared.doesErrorExist(taskId: taskToRun.taskId!) {
                    let errorMessage = "Task: \(taskToRun.describe()) successfully ran, but you have unresolved errors. You should resolve the previously recorded error to Wendy, or return false for running your task."
                    if WendyConfig.strict {
                        fatalError(errorMessage)
                    } else {
                        LogUtil.w(errorMessage)
                    }
                }
                
                LogUtil.d("Task: \(taskToRun.describe()) ran successful.")
                WendyConfig.logTaskComplete(taskToRun, successful: successful)
                
                if PendingTasksUtil.rerunCurrentlyRunningPendingTask {
                    LogUtil.d("Task: \(taskToRun.describe()) is set to re-run. Not deleting it.")
                    try! PendingTasksManager.shared.sendPendingTaskToEndOfTheLine(taskToRun.taskId!)
                } else {
                    LogUtil.d("Deleting task: \(taskToRun.describe()).")
                    try! PendingTasksManager.shared.deleteTask(taskId)
                }
                PendingTasksUtil.resetRerunCurrentlyRunningPendingTask()
                
                runTaskResult = PendingTasksRunnerJobRunResult.successful
                
                self.runTaskDispatchGroup.leave()
                return
            })
            
            _ = self.runTaskDispatchGroup.wait(timeout: .distantFuture)
            return runTaskResult
        }
        
    }
    
    /**
     **Note:** Make sure you call this function from a background thread! You are in charge of doing that, not this function. This function returns a result and behaves in a syncrhonized way so it is not responsible for what thread to run on.
     
     Note: Do not pass in a value for `result` parameter. that is for recusion purposes only.
     
     Example: Check out PendingTasksRunner.Scheduler.scheduleRunAllTasks()
     */
    internal func runAllTasks(filter: RunAllTasksFilter?, result: PendingTasksRunnerResult = PendingTasksRunnerResult()) -> PendingTasksRunnerResult {
        LogUtil.d("Getting next task to run.")
        
        guard let nextTaskToRun = try! PendingTasksManager.shared.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter) else {
            LogUtil.d("All done running tasks.")
            WendyConfig.logAllTasksComplete()
            
            self.resetRunner()
            return result
        }
        
        lastSuccessfulOrFailedTaskId = nextTaskToRun.taskId!
        if (nextTaskToRun.groupId != nil && failedTasksGroups.contains(nextTaskToRun.groupId!)) {
            WendyConfig.logTaskSkipped(nextTaskToRun, reason: ReasonPendingTaskSkipped.partOfFailedGroup)
            LogUtil.d("Task: \(nextTaskToRun.describe()) belongs to a failing group of tasks. Skipping it.")
            return self.runAllTasks(filter: filter, result: result)
        }
        
        let jobRunResult = Scheduler.shared.runPendingTaskWait(nextTaskToRun.taskId!)
        switch jobRunResult {
        case .successful:
            return self.runAllTasks(filter: filter, result: result.addSuccessfulTask())
        case .notSuccessful:
            if let taskGroupId = nextTaskToRun.groupId {
                failedTasksGroups.append(taskGroupId)
            }
            return self.runAllTasks(filter: filter, result: result.addFailedTask())
        case .taskDoesNotExist:
            // Ignore this. If it doesn't exist, it doesn't exist.
            return self.runAllTasks(filter: filter, result: result)
        case .taskSkippedNotReady, .skippedUnresolvedRecordedError:
            if let taskGroupId = nextTaskToRun.groupId {
                failedTasksGroups.append(taskGroupId)
            }
            return self.runAllTasks(filter: filter, result: result)
        }
    }
    
    fileprivate func resetRunner() {
        lastSuccessfulOrFailedTaskId = 0
        failedTasksGroups = []
        currentlyRunningTask = nil
    }
    
    internal class Scheduler {
        
        static let shared = Scheduler()
        
        fileprivate let runPendingTasksDispatchQueue = DispatchQueue(label: "com.levibostian.wendy.PendingTasksRunner.Scheduler.runPendingTasks")
        
        private init() {
        }
        
        internal func runPendingTaskWait(_ taskId: Double) -> PendingTasksRunnerJobRunResult {
            return RunSinglePendingTaskRunner.shared.runPendingTaskWait(taskId)
        }
        
        internal func scheduleRunPendingTask(_ taskId: Double) {
            RunSinglePendingTaskRunner.shared.scheduleRunPendingTask(taskId)
        }
        
        internal func scheduleRunAllTasks(filter: RunAllTasksFilter?) {
            runPendingTasksDispatchQueue.async {
                PendingTasksRunner.shared.runAllTasks(filter: filter)
            }
        }
        
        internal func scheduleRunAllTasksWait(filter: RunAllTasksFilter?) -> PendingTasksRunnerResult {
            return runPendingTasksDispatchQueue.sync { () -> PendingTasksRunnerResult in
                return PendingTasksRunner.shared.runAllTasks(filter: filter)
            }
        }
        
    }
    
    internal enum PendingTasksRunnerJobRunResult {
        case successful
        case notSuccessful
        case taskDoesNotExist
        case taskSkippedNotReady
        case skippedUnresolvedRecordedError
    }
    
}
