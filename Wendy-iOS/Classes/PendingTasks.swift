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
        // TODO do the task factory testing here.

        let persistedPendingTaskId: Double = try PendingTasksManager.sharedInstance.addTask(pendingTask)

        WendyConfig.logNewTaskAdded(pendingTask)
        // TODO run the task in the task runner.
//        self.runTask(id: newPendingTaskForRunner.id, complete: complete, onError: onError)
        // TODO alert listener.

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
