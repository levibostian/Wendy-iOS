import Foundation

internal class LogUtil {
    internal class func d(_ message: String) {
        Task { @MainActor in
            if WendyConfig.debug {
                NSLog("\(WendyConfig.logTag) debug: %@", message)
            }
        }
    }

    internal class func w(_ message: String) {
        Task { @MainActor in
            if WendyConfig.debug {
                NSLog("\(WendyConfig.logTag) WARNING: %@", message)
            }
        }
    }
}

internal extension  LogUtil {
        class func logNewTaskAdded(_ task: PendingTask) {
            Task { @MainActor in
                WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                    weakRefListener.listener?.newTaskAdded(task)
                }
            }
        }

        class func logTaskSkipped(_ task: PendingTask, reason: ReasonPendingTaskSkipped) {
            Task { @MainActor in
                WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                    weakRefListener.listener?.taskSkipped(task, reason: reason)
                }
                WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                    weakRefListener.listener?.skipped(taskId: task.taskId!, reason: reason)
                }
            }
        }

        class func logTaskComplete(_ task: PendingTask, successful: Bool, cancelled: Bool) {
            Task { @MainActor in
                let successful = (successful || cancelled) // to make sure that cancelled marks succcessful as successful, always.
                
                WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                    weakRefListener.listener?.taskComplete(task, successful: successful, cancelled: cancelled)
                }
                WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                    weakRefListener.listener?.complete(taskId: task.taskId!, successful: successful, cancelled: cancelled)
                }
            }
        }

        class func logTaskRunning(_ task: PendingTask) {
            Task { @MainActor in
                WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                    weakRefListener.listener?.runningTask(task)
                }
                WendyConfig.getTaskStatusListenerForTask(task.taskId!).forEach { weakRefListener in
                    weakRefListener.listener?.running(taskId: task.taskId!)
                }
            }
        }

        class func logAllTasksComplete() {
            Task { @MainActor in
                WendyConfig.taskRunnerListeners.forEach { weakRefListener in
                    weakRefListener.listener?.allTasksComplete()
                }
            }
        }
}
