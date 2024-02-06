import CoreData
import Foundation
import UIKit

internal class PendingTasksManager: QueueReader, QueueWriter {
    internal static var shared: PendingTasksManager = PendingTasksManager()
    
    private let coreDataReader = WendyCoreDataQueueReader()
    
    private var queueReaders: [QueueReader] = []
    
    internal static func initForTesting(queueReaders: [QueueReader]) {
        shared = PendingTasksManager()
        shared.queueReaders = queueReaders
    }

    // singleton constructor
    private init() {
        // Set the default, production readers and writers
        queueReaders.append(coreDataReader)
    }

    func add(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        if tag.isEmpty { Fatal.preconditionFailure("You need to set a unique tag for \(String(describing: PendingTask.self)) instances.") }

        let persistedPendingTask: PersistedPendingTask = PersistedPendingTask(tag: tag, dataId: dataId, groupId: groupId)
        CoreDataManager.shared.saveContext()

        let pendingTaskForPersistedPendingTask = persistedPendingTask.pendingTask
        LogUtil.d("Successfully added task to Wendy. Task: \(pendingTaskForPersistedPendingTask.describe())")

        return PendingTask.from(persistedPendingTask: persistedPendingTask)
    }

    internal func getAllTasks() -> [PendingTask] {
        return queueReaders.flatMap { return $0.getAllTasks() }
            .filter { return $0.createdAt != nil }
            .sorted(by: { $0.createdAt! < $1.createdAt! })
    }

    internal func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        return queueReaders.compactMap { return $0.getTaskByTaskId(taskId) }.first
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    func delete(taskId: Double) -> Bool {
        let context = CoreDataManager.shared.viewContext
        
        guard let persistedPendingTask = coreDataReader.getPersistedTaskByTaskId(taskId) else {
            return false
        }
    
        context.delete(persistedPendingTask)
        CoreDataManager.shared.saveContext()
        
        return true
    }

    internal func updatePlaceInLine(_ taskId: Double, createdAt: Date) {
        guard let persistedPendingTask = coreDataReader.getPersistedTaskByTaskId(taskId) else {
            return
        }

        let context = CoreDataManager.shared.viewContext
        persistedPendingTask.setValue(createdAt, forKey: "createdAt")
        CoreDataManager.shared.saveContext()
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        return queueReaders.compactMap { reader in
            return reader.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter)
        }.first
    }
    
    public func addQueueReader(_ queueReader: QueueReader) {
        queueReaders.append(queueReader)
    }
    
}
