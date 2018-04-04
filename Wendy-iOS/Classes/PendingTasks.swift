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
    */
//    public func backgroundFetchRunTasks(completionHandler: @escaping (UIBackgroundFetchResult) -> Void, additionalProcessing: ((_ result: PendingTasksRunnerResult?, _ error: Swift.Error?, _ done: () -> Void) -> Void)? = nil) {
//        func getUIBackgroundFetchResultFrom(_ result: PendingTasksRunnerResult?, error: Swift.Error?) -> UIBackgroundFetchResult {
//            if error != nil {
//                return UIBackgroundFetchResult.failed
//            }
//
//            if result == nil || result!.numberTasksRun == 0 {
//                return UIBackgroundFetchResult.noData
//            } else {
//                return result!.numberSuccessfulTasks > 0 ? UIBackgroundFetchResult.newData : UIBackgroundFetchResult.failed
//            }
//        }
//
//        func doneRunningTasks(result: PendingTasksRunnerResult?, error: Swift.Error?) {
//            if let additionalProcessing = additionalProcessing {
//                additionalProcessing(result, error, {
//                    completionHandler(getUIBackgroundFetchResultFrom(result, error: error))
//                })
//            } else {
//                completionHandler(getUIBackgroundFetchResultFrom(result, error: error))
//            }
//        }
//
//        runTasks(complete: { (result) in
//            doneRunningTasks(result: result, error: nil)
//        }, onError: { (error) in
//            doneRunningTasks(result: nil, error: error)
//        })
//    }

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
    
}
