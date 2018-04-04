//
//  PendingTasks.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/10/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation

public class PendingTasks {

    public static var sharedInstance: PendingTasks = PendingTasks()

    // Setup this way to (1) be a less buggy way of making sure that the developer remembers to call setup() to populate pendingTasksFactory.
    fileprivate var initPendingTasksFactory: PendingTasksFactory?
    internal lazy var pendingTasksFactory: PendingTasksFactory = {
        guard let tasksFactory = initPendingTasksFactory else {
            fatalError("You forgot to setup Wendy via PendingTasks.setup()")
        }
        return tasksFactory
    }()

    private init() {
    }

    public class func setup(tasksFactory: PendingTasksFactory) {
        PendingTasks.sharedInstance.pendingTasksFactory = tasksFactory
    }

    /**
     Convenient function to call in your AppDelegate's `application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)` function for running a background fetch.

     It will return back a `WendyUIBackgroundFetchResult`, and not call the `completionHandler` for you. You need to call that yourself. You can take the `WendyUIBackgroundFetchResult`, pull out the `backgroundFetchResult` processed for you, and return that if you wish to `completionHandler`. Or return your own `UIBakgroundFetchResult` processed yourself from your app or from the Wendy `taskRunnerResult` in the `WendyUIBackgroundFetchResult`.
    */
    public func backgroundFetchRunTasks(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> WendyUIBackgroundFetchResult {
        if !WendyConfig.automaticallyRunTasks {
            LogUtil.d("Wendy configured to *not* automatically run tasks. Skipping execution of background fetch job.")
            return WendyUIBackgroundFetchResult(taskRunnerResult: PendingTasksRunnerResult(), backgroundFetchResult: .noData)
        }

        LogUtil.d("Wendy configured to automatically run tasks. Running the background fetch job.")
        let runAllTasksResult = PendingTasksRunner.Scheduler.sharedInstance.scheduleRunAllTasksWait()

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

    public func addTask(_ pendingTask: PendingTask) throws -> Double {
        _ = self.pendingTasksFactory.getTaskAssertPopulated(tag: pendingTask.tag) // Asserts that you didn't forget to add your PendingTask to the factory. Might as well check for it now while instead of when it's too late! 

        let persistedPendingTaskId: Double = try PendingTasksManager.sharedInstance.addTask(pendingTask)

        WendyConfig.logNewTaskAdded(pendingTask)

        if WendyConfig.automaticallyRunTasks && !pendingTask.manuallyRun {
            LogUtil.d("Wendy is configured to automatically run tasks. Wendy will now attempt to run newly added task: \(pendingTask.describe())")
            runTask(persistedPendingTaskId)
        } else {
            LogUtil.d("Wendy configured to not automatically run tasks. Skipping execution of newly added task: \(pendingTask.describe())")
        }

        return persistedPendingTaskId
    }

    public func runTask(_ taskId: Double) {
        PendingTasksRunner.Scheduler.sharedInstance.scheduleRunPendingTask(taskId)
    }

    public func runTasks() {
        PendingTasksRunner.Scheduler.sharedInstance.scheduleRunAllTasks()
    }

    public func getAllTasks() -> [PendingTask] {
        return PendingTasksManager.sharedInstance.getAllTasks()
    }

    public struct WendyUIBackgroundFetchResult {
        let taskRunnerResult: PendingTasksRunnerResult
        let backgroundFetchResult: UIBackgroundFetchResult
    }
    
}
