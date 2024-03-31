import Foundation

public extension PendingTask {
    func describe() -> String {
        let taskIdString: String = (taskId != nil) ? String(describing: taskId!) : "none"
        let dataString: String = (data != nil) ? String(describing: data!) : "none"
        let groupIdString: String = (groupId != nil) ? String(describing: groupId!) : "none"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm:ss Z"
        let createdAtString: String = (createdAt != nil) ? dateFormatter.string(from: createdAt!) : "none"

        return "taskId: \(taskIdString) data: \(dataString) groupId: \(groupIdString) createdAt: \(createdAtString)"
    }

    func addTaskStatusListenerForTask(listener: PendingTaskStatusListener) {
        if let taskId = self.taskId {
            WendyConfig.addTaskStatusListenerForTask(taskId, listener: listener)
        }
    }

    func hasBeenAddedToWendy() -> Bool {
        return taskId != nil
    }
    
    var dataAsDictionary: [String: AnyHashable] {
        data?.asDictionary() ?? [:]
    }
}
