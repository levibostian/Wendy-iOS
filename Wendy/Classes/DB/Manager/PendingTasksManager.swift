import CoreData
import Foundation
import UIKit

internal class PendingTasksManager {
    internal static let shared: PendingTasksManager = PendingTasksManager()

    private init() {}
    
    internal func addGroupIdToPendingTasksWithoutGroupId() {
        let allTasksWithoutGroupIds = getAllTasks().filter({ $0.groupId == nil || $0.groupId == "" })
        var updateOccurred = false
        for task in allTasksWithoutGroupIds {
            if let taskId = task.taskId, let persistedPendingTask = getTaskByTaskId(taskId) {
                persistedPendingTask.groupId = task.tag
                updateOccurred = true
            }
        }
        if updateOccurred {
            CoreDataManager.shared.saveContext()
        }
    }

    internal func insertPendingTask(_ task: PendingTask) -> PendingTask {
        if task.tag.isEmpty { Fatal.preconditionFailure("You need to set a unique tag for \(String(describing: PendingTask.self)) instances.") }

        let persistedPendingTask: PersistedPendingTask = PersistedPendingTask(pendingTask: task)
        CoreDataManager.shared.saveContext()

        let pendingTaskForPersistedPendingTask = persistedPendingTask.pendingTask
        LogUtil.d("Successfully added task to Wendy. Task: \(pendingTaskForPersistedPendingTask.describe())")

        return pendingTaskForPersistedPendingTask
    }

    /**
     * fatal error if task by taskId does not exist.
     * fatal error if task by taskId does not belong to any groups.
     */
    internal func isTaskFirstTaskOfGroup(_ taskId: Double) -> Bool {
        guard let persistedPendingTask: PersistedPendingTask = getTaskByTaskId(taskId) else {
            fatalError("Task with id: \(taskId) does not exist.")
        }
        
        if persistedPendingTask.groupId == nil {
            Fatal.preconditionFailure("Task: \(persistedPendingTask.pendingTask.describe()) does not belong to a group.")
        }

        let context = CoreDataManager.shared.privateContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "groupId == %@", persistedPendingTask.groupId!)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]

//        do {
//            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
//            return pendingTasks.first!.id == taskId
//        } catch let error as NSError {
//            Fatal.error("Error in Wendy while fetching data from database.", error: error)
//            return false
//        }
        
        var result: Bool = false
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                if let first = pendingTasks.first {
                    result = first.id == taskId
                }
            } catch {}
        }
        
        return result
    }

    internal func getRandomTaskForTag(_ tag: String) -> PendingTask? {
        let context = CoreDataManager.shared.privateContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "(tag == %@)", tag)

//        do {
//            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
//            return pendingTasks.first?.pendingTask
//        } catch let error as NSError {
//            Fatal.error("Error in Wendy while fetching data from database.", error: error)
//            return nil
//        }
        
        var result: PendingTask? = nil
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                result = pendingTasks.first?.pendingTask
            } catch {}
        }
        
        return result
    }
    
    internal func getPendingTasksCount() -> Int {
        let viewContext = CoreDataManager.shared.privateContext
        let pendingTaskFactory = Wendy.shared.pendingTasksFactory
        var count = 0
        viewContext.performAndWait {
            do {
                count = try viewContext.count(for:PersistedPendingTask.fetchRequest())
            } catch {
            }
        }
        return count
    }

    internal func getAllTasks() -> [PendingTask] {
        let viewContext = CoreDataManager.shared.privateContext
        let pendingTaskFactory = Wendy.shared.pendingTasksFactory
        
//        do {
//            let persistedPendingTasks: [PersistedPendingTask] = try viewContext.fetch(PersistedPendingTask.fetchRequest()) as [PersistedPendingTask]
//
//            var pendingTasks: [PendingTask] = []
//            persistedPendingTasks.forEach { persistedPendingTask in
//                pendingTasks.append(persistedPendingTask.pendingTask)
//            }
//
//            return pendingTasks
//        } catch let error as NSError {
//            Fatal.error("Error in Wendy while fetching data from database.", error: error)
//            return []
//        }
        
        var result: [PendingTask] = []
        viewContext.performAndWait {
            do {
                let persistedPendingTasks: [PersistedPendingTask] = try viewContext.fetch(PersistedPendingTask.fetchRequest()) as [PersistedPendingTask]

                var pendingTasks: [PendingTask] = []
                persistedPendingTasks.forEach { persistedPendingTask in
                    pendingTasks.append(persistedPendingTask.pendingTask)
                }
                
                result = pendingTasks
            } catch {}
        }
        
        return result
    }
    
    internal func getExistingTasks(_ task: PendingTask) -> [PersistedPendingTask]? {
        let context = CoreDataManager.shared.privateContext

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

//        do {
//            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
//            return (pendingTasks.isEmpty) ? nil : pendingTasks
//        } catch let error as NSError {
//            Fatal.error("Error in Wendy while fetching data from database.", error: error)
//            return nil
//        }
        
        var result: [PersistedPendingTask]? = nil
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                
                result = (pendingTasks.isEmpty) ? nil : pendingTasks
            } catch { }
        }
        
        return result
    }

    internal func insertPendingTaskError(taskId: Double, humanReadableErrorMessage: String?, errorId: String?) -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = self.getTaskByTaskId(taskId) else {
            return nil
        }

        let persistedPendingTaskError: PersistedPendingTaskError = PersistedPendingTaskError(errorMessage: humanReadableErrorMessage, errorId: errorId, persistedPendingTask: persistedPendingTask)
        CoreDataManager.shared.saveContext()

        let pendingTaskError = PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
        LogUtil.d("Successfully recorded error to Wendy. Error: \(pendingTaskError.describe())")
        
        return pendingTaskError
    }

    internal func getLatestError(pendingTaskId: Double) -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = self.getTaskByTaskId(pendingTaskId) else {
            return nil
        }

        let context = CoreDataManager.shared.privateContext

        let pendingTaskErrorFetchRequest: NSFetchRequest<PersistedPendingTaskError> = PersistedPendingTaskError.fetchRequest()
        pendingTaskErrorFetchRequest.predicate = NSPredicate(format: "pendingTask == %@", persistedPendingTask)

//        do {
//            let pendingTaskErrors: [PersistedPendingTaskError] = try context.fetch(pendingTaskErrorFetchRequest)
//
//            guard let persistedPendingTaskError: PersistedPendingTaskError = pendingTaskErrors.first else {
//                return nil
//            }
//
//            return PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
//        } catch let error as NSError {
//            Fatal.error("Error in Wendy while fetching data from database.", error: error)
//            return nil
//        }
        
        var result: PendingTaskError? = nil
        context.performAndWait {
            do {
                let pendingTaskErrors: [PersistedPendingTaskError] = try context.fetch(pendingTaskErrorFetchRequest)

                guard let persistedPendingTaskError: PersistedPendingTaskError = pendingTaskErrors.first else { return }

                result = PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
            } catch { }
        }
        
        return result
    }

    internal func getAllErrors() -> [PendingTaskError] {
        let viewContext = CoreDataManager.shared.privateContext

//        do {
//            let persistedPendingTaskErrors: [PersistedPendingTaskError] = try viewContext.fetch(PersistedPendingTaskError.fetchRequest()) as [PersistedPendingTaskError]
//
//            var pendingTaskErrors: [PendingTaskError] = []
//            persistedPendingTaskErrors.forEach { taskError in
//                pendingTaskErrors.append(PendingTaskError(from: taskError, pendingTask: taskError.pendingTask!.pendingTask))
//            }
//
//            return pendingTaskErrors
//        } catch let error as NSError {
//            Fatal.error("Error in Wendy while fetching data from database.", error: error)
//            return []
//        }
        
        var result: [PendingTaskError] = []
        viewContext.performAndWait {
            do {
                let persistedPendingTaskErrors: [PersistedPendingTaskError] = try viewContext.fetch(PersistedPendingTaskError.fetchRequest()) as [PersistedPendingTaskError]

                var pendingTaskErrors: [PendingTaskError] = []
                persistedPendingTaskErrors.forEach { taskError in
                    pendingTaskErrors.append(PendingTaskError(from: taskError, pendingTask: taskError.pendingTask!.pendingTask))
                }
                
                result = pendingTaskErrors
            } catch let error as NSError {
//                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        
        return result
    }

    internal func getTaskByTaskId(_ taskId: Double) -> PersistedPendingTask? {
        let context = CoreDataManager.shared.privateContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "id == %f", taskId)

//        do {
//            let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
//            return pendingTasks.first
//        } catch let error as NSError {
//            Fatal.error("Error in Wendy while fetching data from database.", error: error)
//            return nil
//        }
        
        var result: PersistedPendingTask? = nil
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                result = pendingTasks.first
            } catch let error as NSError {
//                Fatal.error("Error in Wendy while fetching data from database.", error: error)
            }
        }
        
        return result
    }

    internal func getPendingTaskTaskById(_ taskId: Double) -> PendingTask? {
        guard let persistedPendingTask = getTaskByTaskId(taskId) else {
            return nil
        }

        return persistedPendingTask.pendingTask
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    internal func deleteTask(_ taskId: Double) {
        let context = CoreDataManager.shared.privateContext
        if let persistedPendingTask = getTaskByTaskId(taskId) {
            context.perform {
                do {
                    context.delete(persistedPendingTask)
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
//                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    NotificationCenter.default.post(name: Notification.Name("wendyCoreDataSaveContextError"), object: "Wendy Coredata error \(nserror), \(nserror.userInfo)")
                    NotificationCenter.default.post(name: Notification.Name("wendyCoreDataSaveContextErrorPendingTaskUserInfo"), object: nserror.userInfo)
                }
            }
        }
    }

    internal func updatePlaceInLine(_ taskId: Double, createdAt: Date) {
        guard let persistedPendingTask = getTaskByTaskId(taskId) else {
            return
        }

        let context = CoreDataManager.shared.privateContext
        persistedPendingTask.setValue(createdAt, forKey: "createdAt")
        CoreDataManager.shared.saveContext()
    }

    internal func deletePendingTaskError(_ taskId: Double) -> Bool {
        let context = CoreDataManager.shared.privateContext
        if let persistedPendingTaskError = getTaskByTaskId(taskId)?.error {
            context.performAndWait {
                do {
                    context.delete(persistedPendingTaskError)
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
//                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    NotificationCenter.default.post(name: Notification.Name("wendyCoreDataSaveContextError"), object: "Wendy Coredata error \(nserror), \(nserror.userInfo)")
                    NotificationCenter.default.post(name: Notification.Name("wendyCoreDataSaveContextErrorPendingTaskUserInfo"), object: nserror.userInfo)
                }
            }
            return true
        }
        return false
    }

    internal func getTotalNumberOfTasksForRunnerToRun(filter: RunAllTasksFilter?) -> Int {
        let context = CoreDataManager.shared.privateContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["manuallyRun = %@": NSNumber(value: false) as NSObject]
        if let filter = filter {
            keyValues = applyFilterPredicates(filter, to: keyValues)
        }

        var result = 0
        context.performAndWait {
            do {
                let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
                pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                result = pendingTasks.count
            } catch let error as NSError{}
        }
        
        return result
    }

    internal func getLastPendingTaskInGroup(_ groupId: String) -> PersistedPendingTask? {
        let context = CoreDataManager.shared.privateContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "groupId == %@", groupId)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: false)]
        
        var result: PersistedPendingTask? = nil
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                result = pendingTasks.first
            } catch let error as NSError{}
        }
        
        return result
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        let context = CoreDataManager.shared.privateContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()

        var keyValues = ["id > %@": lastSuccessfulOrFailedTaskId as NSObject, "manuallyRun = %@": NSNumber(value: false) as NSObject]
        if let filter = filter {
            keyValues = applyFilterPredicates(filter, to: keyValues)
        }

        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]
        
        var result: PendingTask? = nil
        
        context.performAndWait {
            do {
                let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
                if pendingTasks.isEmpty { return }
                let persistedPendingTask: PersistedPendingTask = pendingTasks[0]

                result = persistedPendingTask.pendingTask
            } catch let error as NSError{}
        }
        
        return result
    }

    private func applyFilterPredicates(_ filter: RunAllTasksFilter, to keyValues: [String: NSObject]) -> [String: NSObject] {
        var keyValues = keyValues
        let collections = WendyConfig.collections

        switch filter {
        case .group(let groupId):
            keyValues["groupId = %@"] = groupId as NSObject
        case .collection(let collectionId):
            let collection = collections.getCollection(id: collectionId)

            // Pending tasks where the tag of the pending task is in the collection
            keyValues["tag IN %@"] = collection as NSObject
        }

        return keyValues
    }
}
