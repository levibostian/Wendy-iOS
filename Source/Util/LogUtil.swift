import Foundation

class LogUtil {
    class func d(_ message: String) {
        if WendyConfig.debug {
            NSLog("\(WendyConfig.logTag) debug: %@", message)
        }
    }

    class func w(_ message: String) {
        if WendyConfig.debug {
            NSLog("\(WendyConfig.logTag) WARNING: %@", message)
        }
    }
}

extension LogUtil {
    class func logNewTaskAdded(_ task: PendingTask) {
        for weakRefListener in WendyConfig.taskRunnerListeners {
            weakRefListener.listener?.newTaskAdded(task)
        }
    }

    class func logTaskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
        for weakRefListener in WendyConfig.taskRunnerListeners {
            weakRefListener.listener?.taskSkipped(task, reason: reason)
        }
        for weakRefListener in WendyConfig.getTaskStatusListenerForTask(task.taskId!) {
            weakRefListener.listener?.skipped(taskId: task.taskId!, reason: reason)
        }
    }

    class func logTaskComplete(_ task: PendingTask, successful: Bool, cancelled: Bool) {
        let successful = (successful || cancelled) // to make sure that cancelled marks succcessful as successful, always.

        for weakRefListener in WendyConfig.taskRunnerListeners {
            weakRefListener.listener?.taskComplete(task, successful: successful, cancelled: cancelled)
        }
        for weakRefListener in WendyConfig.getTaskStatusListenerForTask(task.taskId!) {
            weakRefListener.listener?.complete(taskId: task.taskId!, successful: successful, cancelled: cancelled)
        }
    }

    class func logTaskRunning(_ task: PendingTask) {
        for weakRefListener in WendyConfig.taskRunnerListeners {
            weakRefListener.listener?.runningTask(task)
        }
        for weakRefListener in WendyConfig.getTaskStatusListenerForTask(task.taskId!) {
            weakRefListener.listener?.running(taskId: task.taskId!)
        }
    }

    class func logAllTasksComplete() {
        for weakRefListener in WendyConfig.taskRunnerListeners {
            weakRefListener.listener?.allTasksComplete()
        }
    }
}
