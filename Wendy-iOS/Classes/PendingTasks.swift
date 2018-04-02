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

    fileprivate let runTaskDispatchQueue = DispatchQueue(label: "com.levibostian.wendy-ios.PendingTasks.runTask")

    private init() {
    }

    public class func setup(tasksFactory: PendingTasksFactory) {
        PendingTasks.sharedInstance.pendingTasksFactory = tasksFactory
    }
    
//    fileprivate func assertListenersCreated(complete: PendingTasksOnCompleteListener?, onError: PendingTasksOnErrorListener?) -> Listeners {
//        guard let onCompleteListener = complete ?? globalCompleteListener else {
//            fatalError("You did not initialize PendingTasks with config()")
//        }
//        guard let onErrorListener = onError ?? globalOnErrorListener else {
//            fatalError("You did not initialize PendingTasks with config()")
//        }
//        guard pendingTasksFactory != nil else {
//            fatalError("You did not initialize PendingTasks with config()")
//        }
//
//        return Listeners(onComplete: onCompleteListener, onError: onErrorListener)
//    }
//
//    public func runTasks(complete: PendingTasksOnCompleteListener? = nil, onError: PendingTasksOnErrorListener? = nil) {
//        let listeners = assertListenersCreated(complete: complete, onError: onError)
//
//        PendingTasksRunner.sharedInstance.runPendingTasks(complete: listeners.onComplete, onError: listeners.onError)
//    }

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
//
//    public func runTask(id: Double, complete: PendingTasksOnCompleteListener? = nil, onError: PendingTasksOnErrorListener? = nil) {
//        let listeners = assertListenersCreated(complete: complete, onError: onError)
//
//        PendingTasksRunner.sharedInstance.runPendingTask(taskId: id, complete: listeners.onComplete, onError: listeners.onError)
//    }

    public func addTask(_ pendingTask: PendingTask) throws -> Double {
        // TODO do the task factory testing here.

        let persistedPendingTaskId: Double = try PendingTasksManager.sharedInstance.addTask(pendingTask) // swiftlint:disable:this force_try

        WendyConfig.logNewTaskAdded(pendingTask)
        // TODO run the task in the task runner.
//        self.runTask(id: newPendingTaskForRunner.id, complete: complete, onError: onError)
        // TODO alert listener.

        return persistedPendingTaskId
    }

    public func runTask(_ taskId: Double) {
        runTaskDispatchQueue.async {
            PendingTasksRunner.sharedInstance.runPendingTask(taskId: taskId)
        }
    }

//    public func runTasks() {
//        PendingTasksRunner.sharedInstance.runAllTasks()
//    }

    public func getAllTasks() -> [PendingTask] {
        return PendingTasksManager.sharedInstance.getAllTasks()
    }
    
}
