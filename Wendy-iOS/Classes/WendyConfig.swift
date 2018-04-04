//
//  WendyConfig.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 3/27/18.
//

import Foundation

public class WendyConfig {

    public static var automaticallyRunTasks: Bool = true

    fileprivate static var taskRunnerListeners: [WeakReferenceTaskRunnerListener] = []
    public class func addTaskRunnerListener(_ listener: TaskRunnerListener) {
        taskRunnerListeners.append(WeakReferenceTaskRunnerListener(listener: listener))
    }

    private static var taskStatusListeners: [TaskStatusListener] = []
    public class func addTaskStatusListenerForTask(_ taskId: Double, listener: PendingTaskStatusListener) {
        taskStatusListeners.append(TaskStatusListener(taskId: taskId, weakRefListener: WeakReferencePendingTaskStatusListener(listener: listener)))

        // The task runner could be running this task right now and because it takes a while potentially to run a task, I need to notify the listener here. This should be the only use case to handle here, running of a task.
        let taskRunner: PendingTasksRunner = PendingTasksRunner.sharedInstance
        if taskRunner.currentlyRunningTask?.taskId == taskId {
            listener.running(taskId: taskId)
        }
    }
    internal class func getTaskStatusListenerForTask(_ taskId: Double) -> [WeakReferencePendingTaskStatusListener] {
        return taskStatusListeners.filter({ (listener) -> Bool in
            return listener.taskId == taskId
        }).map({ (taskStatusListener) -> WeakReferencePendingTaskStatusListener in
            return taskStatusListener.weakRefListener
        })
    }

    private struct TaskStatusListener {
        let taskId: Double
        let weakRefListener: WeakReferencePendingTaskStatusListener
    }

    public static var debug: Bool = true

}

internal extension WendyConfig {

    internal class func logNewTaskAdded(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.listener.newTaskAdded(task)
            })
        }
    }

    internal class func logTaskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.listener.taskSkipped(task, reason: reason)
            })
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach({ (weakRefListener) in
                weakRefListener.listener.skipped(taskId: task.taskId!, reason: reason)
            })
        }
    }

    internal class func logTaskComplete(_ task: PendingTask, successful: Bool) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.listener.taskComplete(task, successful: successful)
            })
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach({ (weakRefListener) in
                weakRefListener.listener.complete(taskId: task.taskId!, successful: successful)
            })
        }
    }

    internal class func logTaskRunning(_ task: PendingTask) {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.listener.runningTask(task)
            })
            WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach({ (weakRefListener) in
                weakRefListener.listener.running(taskId: task.taskId!)
            })
        }
    }

    internal class func logAllTasksComplete() {
        DispatchQueue.main.async {
            WendyConfig.taskRunnerListeners.forEach({ (weakRefListener) in
                weakRefListener.listener.allTasksComplete()
            })
        }
    }

}
