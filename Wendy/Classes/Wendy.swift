//
//  Wendy.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/10/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation
import Require

public class Wendy {

    public static var shared: Wendy = Wendy()

    // Setup this way to (1) be a less buggy way of making sure that the developer remembers to call setup() to populate pendingTasksFactory.
    fileprivate var initPendingTasksFactory: PendingTasksFactory?
    internal lazy var pendingTasksFactory: PendingTasksFactory = {
        return initPendingTasksFactory.require(hint: "You forgot to setup Wendy via Wendy.setup()")
    }()

    private init() {
    }

    public class func setup(tasksFactory: PendingTasksFactory, debug: Bool = false) {
        WendyConfig.debug = debug
        Wendy.shared.pendingTasksFactory = tasksFactory
    }

    /**
     Convenient function to call in your AppDelegate's `application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)` function for running a background fetch.

     It will return back a `WendyUIBackgroundFetchResult`, and not call the `completionHandler` for you. You need to call that yourself. You can take the `WendyUIBackgroundFetchResult`, pull out the `backgroundFetchResult` processed for you, and return that if you wish to `completionHandler`. Or return your own `UIBakgroundFetchResult` processed yourself from your app or from the Wendy `taskRunnerResult` in the `WendyUIBackgroundFetchResult`.
    */
    public final func backgroundFetchRunTasks(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> WendyUIBackgroundFetchResult {
        if !WendyConfig.automaticallyRunTasks {
            LogUtil.d("Wendy configured to *not* automatically run tasks. Skipping execution of background fetch job.")
            return WendyUIBackgroundFetchResult(taskRunnerResult: PendingTasksRunnerResult(), backgroundFetchResult: .noData)
        }

        LogUtil.d("backgroundFetchRunTasks() called. Wendy configured to automatically run tasks. Running the background fetch job.")
        let runAllTasksResult = PendingTasksRunner.Scheduler.shared.scheduleRunAllTasksWait(filter: nil)

        var backgroundFetchResult: UIBackgroundFetchResult!
        if runAllTasksResult.numberTasksRun == 0 {
            backgroundFetchResult = .noData
        } else if runAllTasksResult.numberSuccessfulTasks >= runAllTasksResult.numberFailedTasks {
            backgroundFetchResult = .newData
        } else {
            backgroundFetchResult = .failed
        }

        return WendyUIBackgroundFetchResult(taskRunnerResult: runAllTasksResult, backgroundFetchResult: backgroundFetchResult)
    }

    public final func addTask(_ pendingTaskToAdd: PendingTask, resolveErrorIfTaskExists: Bool = true) throws -> Double {
        _ = self.pendingTasksFactory.getTaskAssertPopulated(tag: pendingTaskToAdd.tag) // Asserts that you didn't forget to add your PendingTask to the factory. Might as well check for it now while instead of when it's too late!
        
        // We enforce a best practice here.
        if let similarTask = try PendingTasksManager.shared.getRandomTaskForTag(pendingTaskToAdd.tag) {
            if similarTask.groupId == nil && pendingTaskToAdd.groupId != nil {
                try! Fatal.preconditionFailure("Cannot add task: \(pendingTaskToAdd.describe()). All subclasses of a PendingTask must either **all** have a groupId or **none** of them have a groupId. Other \(pendingTaskToAdd.tag)'s you have previously added does not have a groupId. The task you are trying to add does have a groupId.")
            }
            if similarTask.groupId != nil && pendingTaskToAdd.groupId == nil {
                try! Fatal.preconditionFailure("Cannot add task: \(pendingTaskToAdd.describe()). All subclasses of a PendingTask must either **all** have a groupId or **none** of them have a groupId. Other \(pendingTaskToAdd.tag)'s you have previously added does have a groupId. The task you are trying to add does not have a groupId.")
            }
        }
        
        if let existingPendingTasks = try PendingTasksManager.shared.getExistingTasks(pendingTaskToAdd), !existingPendingTasks.isEmpty {
            let sampleExistingPendingTask = existingPendingTasks.last!
            
            if let currentlyRunningTask = PendingTasksRunner.shared.currentlyRunningTask, currentlyRunningTask.equals(sampleExistingPendingTask) {
                PendingTasksUtil.rerunCurrentlyRunningPendingTask = true
            }
            if try doesErrorExist(taskId: sampleExistingPendingTask.id) && resolveErrorIfTaskExists {
                for pendingTask in existingPendingTasks {
                    try resolveError(taskId: pendingTask.id)
                }
            }
            if let groupId = pendingTaskToAdd.groupId {
                if let lastPendingTaskInGroup = try PendingTasksManager.shared.getLastPendingTaskInGroup(groupId), lastPendingTaskInGroup.pendingTask.equals(pendingTaskToAdd) {
                    return lastPendingTaskInGroup.id
                }
            } else {
                return sampleExistingPendingTask.id
            }
        }

        let addedPendingTask: PendingTask = try PendingTasksManager.shared.insertPendingTask(pendingTaskToAdd)

        WendyConfig.logNewTaskAdded(pendingTaskToAdd)

        try self.runTaskAutomaticallyIfAbleTo(addedPendingTask)

        return addedPendingTask.taskId!
    }
    
    /**
     * Note: This function is for internal use only. There are no checks to make sure that it exists and stuff. It's assumed you know what you're doing.
     
     This function exists for this scenario:
     1. Only run depending on WendyConfig.automaticallyRunTasks.
     2. If task is *able* to run.
     
     Those make this function unique compared to `runTask()` because that function ignores WendyConfig.automaticallyRunTasks *and* if the task.manuallyRun property is set or not.
     */
    internal func runTaskAutomaticallyIfAbleTo(_ task: PendingTask) throws -> Bool {
        if !WendyConfig.automaticallyRunTasks {
            LogUtil.d("Wendy configured to not automatically run tasks. Skipping execution of newly added task: \(task.describe())")
            return false
        }
        if task.manuallyRun {
            LogUtil.d("Task is set to manually run. Skipping execution of newly added task: \(task.describe())")
            return false
        }
        if try !self.isTaskAbleToManuallyRun(task.taskId!) {
            LogUtil.d("Task is not able to manually run. Skipping execution of newly added task: \(task.describe())")
            return false
        }
        
        LogUtil.d("Wendy is configured to automatically run tasks. Wendy will now attempt to run newly added task: \(task.describe())")
        try self.runTask(task.taskId!)
        
        return true
    }

    public final func runTask(_ taskId: Double) throws {
        let pendingTask: PendingTask = try self.assertPendingTaskExists(taskId)
        
        if try !self.isTaskAbleToManuallyRun(taskId) {
            try! Fatal.preconditionFailure("Task is not able to manually run. Task: \(pendingTask.describe())")
        }
        
        PendingTasksRunner.Scheduler.shared.scheduleRunPendingTask(taskId)
    }
    
    public final func isTaskAbleToManuallyRun(_ taskId: Double) throws -> Bool {
        let pendingTask: PendingTask = try self.assertPendingTaskExists(taskId)
    
        if pendingTask.groupId == nil {
            return true
        }
        return try PendingTasksManager.shared.isTaskFirstTaskOfGroup(taskId)
    }
    
    /**
     * Checks to make sure that a [PendingTask] does exist in the database, else throw an exception.
     *
     * Why throw an exception? I used to simply ignore your request if you called a function such as [recordError] if you gave a taskId parameter for a task that did not exist in the database. But I decided to remove that because [PendingTask] should always be found in the database unless one of the following happens:
     *
     * 1. You did not add the [PendingTask] to the database in the first place which you should get an exception thrown on you then to make sure you fix that.
     * 2. The [PendingTask] previously existed, but the task ran successfully and the task runner deleted. In that case, you *should* not be doing actions such as trying to record errors then, right? You should have returns [PendingTaskResult.FAILED] instead which will not delete your task.
     *
     * You do not need to use this function. But you should use it if there is a scenario when a [PendingTask] could be deleted and your code tries to perform an action on it. Race conditions are real and we do keep them in mind. But if your code *should* be following best practices, then we should throw exceptions instead to get you to fix your code.
     */
    internal func assertPendingTaskExists(_ taskId: Double) throws -> PendingTask {
        let pendingTask: PendingTask? = try PendingTasksManager.shared.getPendingTaskTaskById(taskId)
        if pendingTask == nil {
            Fatal.preconditionFailure("Task with id: \(taskId) does not exist.")
        }
        return pendingTask!
    }

    public final func runTasks(filter: RunAllTasksFilter?) {
        PendingTasksRunner.Scheduler.shared.scheduleRunAllTasks(filter: filter)
    }

    public final func getAllTasks() -> [PendingTask] {
        return PendingTasksManager.shared.getAllTasks()
    }
    
    public final func recordError(taskId: Double, humanReadableErrorMessage: String?, errorId: String?) throws {
        let pendingTask: PendingTask = try self.assertPendingTaskExists(taskId)
        
        try PendingTasksManager.shared.insertPendingTaskError(taskId: taskId, humanReadableErrorMessage: humanReadableErrorMessage, errorId: errorId)
        
        WendyConfig.logErrorRecorded(pendingTask, errorMessage: humanReadableErrorMessage, errorId: errorId)
    }
    
    public final func getLatestError(taskId: Double) throws -> PendingTaskError? {
        let _: PendingTask = try self.assertPendingTaskExists(taskId)
        
        return try PendingTasksManager.shared.getLatestError(pendingTaskId: taskId)
    }
    
    public final func doesErrorExist(taskId: Double) throws -> Bool {
        return try self.getLatestError(taskId: taskId) != nil
    }
    
    public final func resolveError(taskId: Double) throws -> Bool {
        let pendingTask: PendingTask = try self.assertPendingTaskExists(taskId)
        
        if try PendingTasksManager.shared.deletePendingTaskError(taskId) {
            WendyConfig.logErrorResolved(pendingTask)
            LogUtil.d("Task: \(pendingTask.describe()) successfully resolved previously recorded error.")
            
            if let pendingTaskGroupId = pendingTask.groupId {
                self.runTasks(filter: RunAllTasksFilter(groupId: pendingTaskGroupId))
            } else {
                try self.runTaskAutomaticallyIfAbleTo(pendingTask)
            }
            
            return true
        }
        return false
    }
    
    public final func getAllErrors() -> [PendingTaskError] {
        return PendingTasksManager.shared.getAllErrors()
    }

    public struct WendyUIBackgroundFetchResult {
        public let taskRunnerResult: PendingTasksRunnerResult
        public let backgroundFetchResult: UIBackgroundFetchResult
    }
    
}
