import CoreData
import Foundation
import UIKit

internal class PendingTasksManager: QueueReader, QueueWriter {
    internal static let shared: PendingTasksManager = PendingTasksManager()

    private init() {}

    func add(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        if tag.isEmpty { Fatal.preconditionFailure("You need to set a unique tag for \(String(describing: PendingTask.self)) instances.") }

        let persistedPendingTask: PersistedPendingTask = PersistedPendingTask(tag: tag, dataId: dataId, groupId: groupId)
        CoreDataManager.shared.saveContext()

        let pendingTaskForPersistedPendingTask = persistedPendingTask.pendingTask
        LogUtil.d("Successfully added task to Wendy. Task: \(pendingTaskForPersistedPendingTask.describe())")

        return PendingTask.from(persistedPendingTask: persistedPendingTask)
    }

    internal func getAllTasks() -> [PendingTask] {
        let viewContext = CoreDataManager.shared.viewContext

        do {
            let persistedPendingTasks: [PersistedPendingTask] = try viewContext.fetch(PersistedPendingTask.fetchRequest()) as [PersistedPendingTask]

            var pendingTasks: [PendingTask] = []
            persistedPendingTasks.forEach { persistedPendingTask in
                pendingTasks.append(persistedPendingTask.pendingTask)
            }

            return pendingTasks
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return []
        }
    }

    private func getPersistedTaskByTaskId(_ taskId: Double) -> PersistedPendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "id == %f", taskId)

        do {
            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
            return pendingTasks.first
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return nil
        }
    }

    internal func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        guard let persistedPendingTask = getPersistedTaskByTaskId(taskId) else {
            return nil
        }

        return persistedPendingTask.pendingTask
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    func delete(taskId: Double) -> Bool {
        let context = CoreDataManager.shared.viewContext
        
        guard let persistedPendingTask = getPersistedTaskByTaskId(taskId) else {
            return false
        }
    
        context.delete(persistedPendingTask)
        CoreDataManager.shared.saveContext()
        
        return true
    }

    internal func updatePlaceInLine(_ taskId: Double, createdAt: Date) {
        guard let persistedPendingTask = getPersistedTaskByTaskId(taskId) else {
            return
        }

        let context = CoreDataManager.shared.viewContext
        persistedPendingTask.setValue(createdAt, forKey: "createdAt")
        CoreDataManager.shared.saveContext()
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["id > %@": lastSuccessfulOrFailedTaskId as NSObject, "manuallyRun = %@": NSNumber(value: false) as NSObject]
        if let filter = filter {
            keyValues = applyFilterPredicates(filter, to: keyValues)
        }

        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]

        do {
            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
            if pendingTasks.isEmpty { return nil }
            let persistedPendingTask: PersistedPendingTask = pendingTasks[0]

            return persistedPendingTask.pendingTask
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return nil
        }
    }

    private func applyFilterPredicates(_ filter: RunAllTasksFilter, to keyValues: [String: NSObject]) -> [String: NSObject] {
        var keyValues = keyValues

        switch filter {
        case .group(let groupId):
            keyValues["groupId = %@"] = groupId as NSObject
        }

        return keyValues
    }
}
