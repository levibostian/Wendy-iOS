//
//  PendingTasksManager.swift
//  Wendy-iOS
//
//  Created by Levi Bostian on 11/9/17.
//  Copyright © 2017 Curiosity IO. All rights reserved.
//

import Foundation
import CoreData
import UIKit

internal class PendingTasksManager {
    
    internal static let shared: PendingTasksManager = PendingTasksManager()
    
    private init() {
    }
    
    /**
     * Note: If you attempt to add a [PendingTask] instance of a [PendingTask] that already exists, your request will be ignored and not written to the database.
     */
    internal func insertPendingTask( _ task: PendingTask) throws -> PendingTask {
        if task.tag.isEmpty { fatalError("You need to set a unique tag for \(String(describing: PendingTask.self)) instances.") }
        
        if let existingPendingTask = try self.getExistingTask(task) {
            return existingPendingTask.pendingTask
        }
        
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
    internal func isTaskFirstTaskOfGroup(_ taskId: Double) throws -> Bool {
        guard let persistedPendingTask: PersistedPendingTask = try self.getTaskByTaskId(taskId) else {
            fatalError("Task with id: \(taskId) does not exist.")
        }
        if persistedPendingTask.groupId == nil {
            fatalError("Task: \(persistedPendingTask.pendingTask.describe()) does not belong to a group.")
        }
        
        let context = CoreDataManager.shared.viewContext
        
        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "groupId == %@", persistedPendingTask.groupId!)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]
        
        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        return pendingTasks.first!.id == taskId
    }
    
    internal func getRandomTaskForTag(_ tag: String) throws -> PendingTask? {
        let context = CoreDataManager.shared.viewContext
        
        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "(tag == %@)", tag)
        
        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        return pendingTasks.first?.pendingTask
    }
    
    internal func getAllTasks() -> [PendingTask] {
        let viewContext = CoreDataManager.shared.viewContext
        let pendingTaskFactory = Wendy.shared.pendingTasksFactory
        let persistedPendingTasks: [PersistedPendingTask] = try! viewContext.fetch(PersistedPendingTask.fetchRequest()) as [PersistedPendingTask]

        var pendingTasks: [PendingTask] = []
        persistedPendingTasks.forEach { (persistedPendingTask) in
            pendingTasks.append(persistedPendingTask.pendingTask)
        }

        return pendingTasks
    }
    
    internal func getExistingTask(_ task: PendingTask) throws -> PersistedPendingTask? {
        let context = CoreDataManager.shared.viewContext
        
        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        if let taskDataId = task.dataId {
            pendingTaskFetchRequest.predicate = NSPredicate(format: "(dataId == %@) AND (tag == %@)", taskDataId, task.tag)
        } else {
            pendingTaskFetchRequest.predicate = NSPredicate(format: "(tag == %@)", task.tag)
        }
        
        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        return pendingTasks.first
    }
    
    internal func insertPendingTaskError(taskId: Double, humanReadableErrorMessage: String?, errorId: String?) throws -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = try self.getTaskByTaskId(taskId) else {
            return nil
        }
        
        let persistedPendingTaskError: PersistedPendingTaskError = PersistedPendingTaskError(errorMessage: humanReadableErrorMessage, errorId: errorId, persistedPendingTask: persistedPendingTask)
        CoreDataManager.shared.saveContext()
        
        let pendingTaskError = PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
        LogUtil.d("Successfully recorded error to Wendy. Error: \(pendingTaskError.describe())")
        
        return pendingTaskError
    }
    
    internal func getLatestError(pendingTaskId: Double) throws -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = try self.getTaskByTaskId(pendingTaskId) else {
            return nil
        }
        
        let context = CoreDataManager.shared.viewContext
        
        let pendingTaskErrorFetchRequest: NSFetchRequest<PersistedPendingTaskError> = PersistedPendingTaskError.fetchRequest()
        pendingTaskErrorFetchRequest.predicate = NSPredicate(format: "pendingTask == %@", persistedPendingTask)
        let pendingTaskErrors: [PersistedPendingTaskError] = try context.fetch(pendingTaskErrorFetchRequest)
        
        guard let persistedPendingTaskError: PersistedPendingTaskError = pendingTaskErrors.first else {
            return nil
        }
        
        return PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
    }
    
    internal func getAllErrors() -> [PendingTaskError] {
        let viewContext = CoreDataManager.shared.viewContext
        let persistedPendingTaskErrors: [PersistedPendingTaskError] = try! viewContext.fetch(PersistedPendingTaskError.fetchRequest()) as [PersistedPendingTaskError]
        
        var pendingTaskErrors: [PendingTaskError] = []
        persistedPendingTaskErrors.forEach { (taskError) in
            pendingTaskErrors.append(PendingTaskError(from: taskError, pendingTask: taskError.pendingTask!.pendingTask))
        }
        
        return pendingTaskErrors
    }
    
    internal func getTaskByTaskId(_ taskId: Double) throws -> PersistedPendingTask? {
        let context = CoreDataManager.shared.viewContext
        
        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "id == %f", taskId)
        
        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        return pendingTasks.first
    }

    internal func getPendingTaskTaskById(_ taskId: Double) throws -> PendingTask? {
        guard let persistedPendingTask = try getTaskByTaskId(taskId) else {
            return nil
        }

        return persistedPendingTask.pendingTask
    }

    // Note: Make sure to keep the query at "delete this table item by ID _____".
    // Because of this scenario: The runner is running a task with ID 1. While the task is running a user decides to update that data. This results in having to run that PendingTask a 2nd time (if the running task is successful) to sync the newest changes. To assert this 2nd change, we take advantage of SQLite's unique constraint. On unique constraint collision we replace (update) the data in the database which results in all the PendingTask data being the same except for the ID being incremented. So, after the runner runs the task successfully and wants to delete the task here, it will not delete the task because the ID no longer exists. It has been incremented so the newest changes can be run.
    internal func deleteTask(_ taskId: Double) throws {
        let context = CoreDataManager.shared.viewContext
        if let persistedPendingTask = try getTaskByTaskId(taskId) {
            context.delete(persistedPendingTask)
            CoreDataManager.shared.saveContext()
        }
    }
    
    internal func sendPendingTaskToEndOfTheLine(_ taskId: Double) throws {
        guard let persistedPendingTask = try getTaskByTaskId(taskId) else {
            return
        }
        
        let context = CoreDataManager.shared.viewContext
        persistedPendingTask.setValue(Date(), forKey: "createdAt")
        try context.save()
    }
    
    internal func deletePendingTaskError(_ taskId: Double) throws -> Bool {
        let context = CoreDataManager.shared.viewContext
        if let persistedPendingTaskError = try getTaskByTaskId(taskId)?.error {
            context.delete(persistedPendingTaskError)
            CoreDataManager.shared.saveContext()
            return true
        }
        return false
    }
    
    internal func getTotalNumberOfTasksForRunnerToRun(filter: RunAllTasksFilter?) throws -> Int {
        let context = CoreDataManager.shared.viewContext
        
        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        
        var keyValues = ["manuallyRun = %@": NSNumber(booleanLiteral: false) as NSObject]
        if let filterByGroupId = filter?.groupId {
            keyValues["groupId = %@"] = filterByGroupId as NSObject
        }
        
        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        return pendingTasks.count
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) throws -> PendingTask? {
        let context = CoreDataManager.shared.viewContext
        
        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        
        var keyValues = ["id > %f": lastSuccessfulOrFailedTaskId as NSObject, "manuallyRun = %@": NSNumber(booleanLiteral: false) as NSObject]
        if let filterByGroupId = filter?.groupId {
            keyValues["groupId = %@"] = filterByGroupId as NSObject
        }
        
        let predicates = keyValues.map { NSPredicate(format: $0.key, $0.value) }
        pendingTaskFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.createdAt), ascending: true)]

        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        if pendingTasks.isEmpty { return nil }
        let persistedPendingTask: PersistedPendingTask = pendingTasks[0]

        return persistedPendingTask.pendingTask
    }

}
