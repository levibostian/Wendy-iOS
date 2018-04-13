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
    
    internal static let sharedInstance: PendingTasksManager = PendingTasksManager()
    
    private init() {
    }
    
    internal func addTask(_ task: PendingTask) throws -> Double {
        let persistedPendingTask: PersistedPendingTask = PersistedPendingTask(pendingTask: task)
        CoreDataManager.sharedInstance.saveContext()

        return persistedPendingTask.id
    }

    internal func getAllTasks() -> [PendingTask] {
        let viewContext = CoreDataManager.sharedInstance.viewContext
        let pendingTaskFactory = PendingTasks.sharedInstance.pendingTasksFactory
        let persistedPendingTasks: [PersistedPendingTask] = try! viewContext.fetch(PersistedPendingTask.fetchRequest()) as [PersistedPendingTask]

        var pendingTasks: [PendingTask] = []
        persistedPendingTasks.forEach { (persistedPendingTask) in
            pendingTasks.append(persistedPendingTask.pendingTask)
        }

        return pendingTasks
    }
    
    internal func insertPendingTaskError(taskId: Double, humanReadableErrorMessage: String?, errorId: String?) throws -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = try self.getTaskByTaskId(taskId) else {
            return nil
        }
        
        let persistedPendingTaskError: PersistedPendingTaskError = PersistedPendingTaskError(errorMessage: humanReadableErrorMessage, errorId: errorId, persistedPendingTask: persistedPendingTask)
        CoreDataManager.sharedInstance.saveContext()
        
        let pendingTaskError = PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
        LogUtil.d("Successfully recorded error to Wendy. Error: \(pendingTaskError.describe())")
        
        return pendingTaskError
    }
    
    internal func getLatestError(pendingTaskId: Double) throws -> PendingTaskError? {
        guard let persistedPendingTask: PersistedPendingTask = try self.getTaskByTaskId(pendingTaskId) else {
            return nil
        }
        
        let context = CoreDataManager.sharedInstance.viewContext
        
        let pendingTaskErrorFetchRequest: NSFetchRequest<PersistedPendingTaskError> = PersistedPendingTaskError.fetchRequest()
        pendingTaskErrorFetchRequest.predicate = NSPredicate(format: "pendingTask == %@", persistedPendingTask)
        let pendingTaskErrors: [PersistedPendingTaskError] = try context.fetch(pendingTaskErrorFetchRequest)
        
        guard let persistedPendingTaskError: PersistedPendingTaskError = pendingTaskErrors.first else {
            return nil
        }
        
        return PendingTaskError(from: persistedPendingTaskError, pendingTask: persistedPendingTask.pendingTask)
    }
    
    internal func getAllErrors() -> [PendingTaskError] {
        let viewContext = CoreDataManager.sharedInstance.viewContext
        let persistedPendingTaskErrors: [PersistedPendingTaskError] = try! viewContext.fetch(PersistedPendingTaskError.fetchRequest()) as [PersistedPendingTaskError]
        
        var pendingTaskErrors: [PendingTaskError] = []
        persistedPendingTaskErrors.forEach { (taskError) in
            pendingTaskErrors.append(PendingTaskError(from: taskError, pendingTask: taskError.pendingTask!.pendingTask))
        }
        
        return pendingTaskErrors
    }
    
    internal func getTaskByTaskId(_ taskId: Double) throws -> PersistedPendingTask? {
        let context = CoreDataManager.sharedInstance.viewContext
        
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

    internal func deleteTask(_ taskId: Double) throws {
        let context = CoreDataManager.sharedInstance.viewContext
        if let persistedPendingTask = try getTaskByTaskId(taskId) {
            context.delete(persistedPendingTask)
            CoreDataManager.sharedInstance.saveContext()
        }
    }
    
    internal func deletePendingTaskError(_ taskId: Double) throws {
        let context = CoreDataManager.sharedInstance.viewContext
        if let persistedPendingTaskError = try getTaskByTaskId(taskId)?.error {
            context.delete(persistedPendingTaskError)
            CoreDataManager.sharedInstance.saveContext()
        }
    }

    internal func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double) throws -> PendingTask? {
        let context = CoreDataManager.sharedInstance.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "id > %f AND manuallyRun = false", lastSuccessfulOrFailedTaskId)
        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedPendingTask.id), ascending: true)]

        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        if pendingTasks.isEmpty { return nil }
        let persistedPendingTask: PersistedPendingTask = pendingTasks[0]

        return persistedPendingTask.pendingTask
    }

}
