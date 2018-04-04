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

 1. when you call `PendingTasks.runTask()` it returns instantly to you. It does *not* block the calling thread. It's like it schedules a job to run in the future.
 2. X number of threads all running the task runner's `runTask()` function can only run one at a time. (so, run runTask() in a sync way)
 3. The task runner's `runTask()` runs in a sync way (while the `PendingTask.runTask()` is async) where it does not return a result until the task has failed or succeeded. So, work in a blocking way.
 */
internal class PendingTasksRunner {
    
    internal static var sharedInstance: PendingTasksRunner = PendingTasksRunner()
    
    private init() {
    }

    fileprivate var lastSuccessfulOrFailedTaskId: Double = 0
    fileprivate var failedTasksGroups: [String] = []
    internal var currentlyRunningTask: PendingTask?

    // I created a separate class for running a single pending task simply as a wrapper to the function runPendingTask(taskId).
    // this function is very important to have it run in a synchronized way and to enforce that, I need to make sure it uses a DispatchQueue to run all of it's callers requests. So, I created this class to make sure I don't make the mistake of accidently calling this `runPendingTask(taskId)` function inside of the `PendingTasksRunner` without following my rule of *this function must run in a synchonized way!* (I already made this mistake....)
    fileprivate class RunSinglePendingTaskRunner {

        static let sharedInstance = RunSinglePendingTaskRunner()

        private let runPendingTaskDispatchQueue = DispatchQueue(label: "com.levibostian.wendy-ios.PendingTasksRunner.Scheduler.runPendingTask")
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

        private func runPendingTask(taskId: Double) -> PendingTasksRunnerJobRunResult {
            self.runTaskDispatchGroup.enter()
            var runTaskResult: PendingTasksRunnerJobRunResult!

            guard let persistedPendingTaskId: Double = try! PendingTasksManager.sharedInstance.getTaskByTaskId(taskId)?.id else {
                runTaskResult = PendingTasksRunnerJobRunResult.taskDoesNotExist

                self.runTaskDispatchGroup.leave()
                return runTaskResult // This code should *not* be executed because of .leave() above.
            }
            let taskToRun: PendingTask = try! PendingTasksManager.sharedInstance.getPendingTaskTaskById(taskId)!

            if !taskToRun.canRunTask() {
                WendyConfig.logTaskSkipped(taskToRun, reason: ReasonPendingTaskSkipped.notReadyToRun)
                LogUtil.d("Task: \(taskToRun.describe()) is not ready to run. Skipping it.")
                runTaskResult = PendingTasksRunnerJobRunResult.taskSkippedNotReady

                self.runTaskDispatchGroup.leave()
            } else {
                PendingTasksRunner.sharedInstance.currentlyRunningTask = taskToRun

                WendyConfig.logTaskRunning(taskToRun)
                LogUtil.d("Running task: \(taskToRun.describe())")
                taskToRun.runTask(complete: { (successful: Bool) in
                    PendingTasksRunner.sharedInstance.currentlyRunningTask = nil

                    if !successful {
                        LogUtil.d("Task: \(taskToRun.describe()) failed but will reschedule it. Skipping it.")
                        WendyConfig.logTaskComplete(taskToRun, successful: successful)
                        runTaskResult = PendingTasksRunnerJobRunResult.notSuccessful

                        self.runTaskDispatchGroup.leave()
                        return
                    }

                    LogUtil.d("Task: \(taskToRun.describe()) ran successful. Deleting it.")
                    WendyConfig.logTaskComplete(taskToRun, successful: successful)
                    try! PendingTasksManager.sharedInstance.deleteTask(taskId)
                    runTaskResult = PendingTasksRunnerJobRunResult.successful

                    self.runTaskDispatchGroup.leave()
                })
            }

            _ = self.runTaskDispatchGroup.wait(timeout: .distantFuture)
            return runTaskResult
        }

    }

    /**
     **Note:** Make sure you call this function from a background thread! You are in charge of doing that, not this function. This function returns a result and behaves in a syncrhonized way so it is not responsible for what thread to run on.

     Example: Check out PendingTasksRunner.Scheduler.scheduleRunAllTasks()
     */
    internal func runAllTasks(_ result: PendingTasksRunnerResult = PendingTasksRunnerResult()) -> PendingTasksRunnerResult {
        LogUtil.d("Getting next task to run.")

        guard let nextTaskToRun = try! PendingTasksManager.sharedInstance.getNextTaskToRun(lastSuccessfulOrFailedTaskId) else {
            LogUtil.d("All done running tasks.")
            WendyConfig.logAllTasksComplete()

            self.resetRunner()
            return result
        }

        lastSuccessfulOrFailedTaskId = nextTaskToRun.taskId!
        if (nextTaskToRun.groupId != nil && failedTasksGroups.contains(nextTaskToRun.groupId!)) {
            WendyConfig.logTaskSkipped(nextTaskToRun, reason: ReasonPendingTaskSkipped.partOfFailedGroup)
            LogUtil.d("Task: \(nextTaskToRun.describe()) belongs to a failing group of tasks. Skipping it.")
            return self.runAllTasks(result)
        }

        let jobRunResult = Scheduler.sharedInstance.runPendingTaskWait(nextTaskToRun.taskId!)
        switch jobRunResult {
        case .successful:
            return self.runAllTasks(result.addSuccessfulTask())
        case .notSuccessful:
            if let taskGroupId = nextTaskToRun.groupId {
                failedTasksGroups.append(taskGroupId)
            }
            return self.runAllTasks(result.addFailedTask())
        case .taskDoesNotExist:
            // Ignore this. If it doesn't exist, it doesn't exist.
            return self.runAllTasks(result)
        case .taskSkippedNotReady:
            if let taskGroupId = nextTaskToRun.groupId {
                failedTasksGroups.append(taskGroupId)
            }
            return self.runAllTasks(result)
        }
    }

    fileprivate func resetRunner() {
        lastSuccessfulOrFailedTaskId = 0
        failedTasksGroups = []
        currentlyRunningTask = nil
    }

    internal class Scheduler {

        static let sharedInstance = Scheduler()

        fileprivate let runPendingTasksDispatchQueue = DispatchQueue(label: "com.levibostian.wendy-ios.PendingTasksRunner.Scheduler.runPendingTasks")

        private init() {
        }

        internal func runPendingTaskWait(_ taskId: Double) -> PendingTasksRunnerJobRunResult {
            return RunSinglePendingTaskRunner.sharedInstance.runPendingTaskWait(taskId)
        }

        internal func scheduleRunPendingTask(_ taskId: Double) {
            RunSinglePendingTaskRunner.sharedInstance.scheduleRunPendingTask(taskId)
        }

        internal func scheduleRunAllTasks() {
            runPendingTasksDispatchQueue.async {
                PendingTasksRunner.sharedInstance.runAllTasks()
            }
        }

        internal func scheduleRunAllTasksWait() -> PendingTasksRunnerResult {
            return runPendingTasksDispatchQueue.sync { () -> PendingTasksRunnerResult in
                return PendingTasksRunner.sharedInstance.runAllTasks()
            }
        }

    }

    internal enum PendingTasksRunnerJobRunResult {
        case successful
        case notSuccessful
        case taskDoesNotExist
        case taskSkippedNotReady
    }

}
