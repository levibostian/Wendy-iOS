import CoreData
import Foundation
import UIKit
import Wendy

public class WendyCoreDataQueueReader: QueueReader {
    public init() {}

    internal func insertPendingTask(_ task: PendingTask) -> PendingTask {
        if task.tag.isEmpty { Fatal.preconditionFailure("You need to set a unique tag for \(String(describing: PendingTask.self)) instances.") }

        let persistedPendingTask: PersistedPendingTask = PersistedPendingTask(pendingTask: task)
        CoreDataManager.shared.saveContext()

        let pendingTaskForPersistedPendingTask = persistedPendingTask.pendingTask

        return pendingTaskForPersistedPendingTask
    }

    /**
     * fatal error if task by taskId does not exist.
     * fatal error if task by taskId does not belong to any groups.
     */
    internal func isTaskFirstTaskOfGroup(_ taskId: Double) -> Bool {
        guard let persistedPendingTask: PersistedPendingTask = getPersistedTaskByTaskId(taskId) else {
            fatalError("Task with id: \(taskId) does not exist.")
        }
        
        if persistedPendingTask.groupId == nil {
            Fatal.preconditionFailure("Task: \(persistedPendingTask.pendingTask.describe()) does not belong to a group.")
        }

        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "groupId == %@", persistedPendingTask.groupId!)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]

        do {
            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
            return pendingTasks.first!.id == taskId
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return false
        }
    }

    internal func getRandomTaskForTag(_ tag: String) -> PendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "(tag == %@)", tag)

        do {
            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
            return pendingTasks.first?.pendingTask
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return nil
        }
    }

    public func getAllTasks() -> [PendingTask] {
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

    internal func getExistingTasks(_ task: PendingTask) -> [PendingTask]? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["tag = %@": task.tag as NSObject]
        if let groupId = task.groupId {
            keyValues["groupId = %@"] = groupId as NSObject
        }
        if let dataId = task.dataId {
            keyValues["dataId = %@"] = dataId as NSObject
        }

        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]

        do {
            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
            return (pendingTasks.isEmpty) ? nil : pendingTasks.map { $0.pendingTask }
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return nil
        }
    }

    internal func getPersistedTaskByTaskId(_ taskId: Double) -> PersistedPendingTask? {
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

    public func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        guard let persistedPendingTask = getPersistedTaskByTaskId(taskId) else {
            return nil
        }

        return persistedPendingTask.pendingTask
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    internal func deleteTask(_ taskId: Double) {
        let context = CoreDataManager.shared.viewContext
        if let persistedPendingTask = getPersistedTaskByTaskId(taskId) {
            context.delete(persistedPendingTask)
            CoreDataManager.shared.saveContext()
        }
    }

    internal func updatePlaceInLine(_ taskId: Double, createdAt: Date) {
        guard let persistedPendingTask = getPersistedTaskByTaskId(taskId) else {
            return
        }

        let context = CoreDataManager.shared.viewContext
        persistedPendingTask.setValue(createdAt, forKey: "createdAt")
        CoreDataManager.shared.saveContext()
    }

    internal func getTotalNumberOfTasksForRunnerToRun(filter: RunAllTasksFilter?) -> Int {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["manuallyRun = %@": NSNumber(value: false) as NSObject]
        if let filter = filter {
            keyValues = applyFilterPredicates(filter, to: keyValues)
        }

        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
            return pendingTasks.count
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return 0
        }
    }

    internal func getLastPendingTaskInGroup(_ groupId: String) -> PendingTask? {
        let context = CoreDataManager.shared.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "groupId == %@", groupId)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: false)]

        do {
            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
            return pendingTasks.first.map { $0.pendingTask }
        } catch let error as NSError {
            Fatal.error("Error in Wendy while fetching data from database.", error: error)
            return nil
        }
    }

    public func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
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
