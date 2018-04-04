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
            var blankPendingTask = pendingTaskFactory.getTask(tag: persistedPendingTask.tag!)
            blankPendingTask.populate(from: persistedPendingTask)
            pendingTasks.append(blankPendingTask)
        }

        return pendingTasks
    }
    
    internal func getTaskByTaskId(_ taskId: Double) throws -> PersistedPendingTask? {
        let context = CoreDataManager.sharedInstance.viewContext

        let pendingTaskFetchRequest: NSFetchRequest<PersistedPendingTask> = PersistedPendingTask.fetchRequest()
        pendingTaskFetchRequest.predicate = NSPredicate(format: "id == %f", taskId)

        let pendingTasks: [PersistedPendingTask] = try context.fetch(pendingTaskFetchRequest)
        return pendingTasks.isEmpty ? nil : pendingTasks[0]
    }

    internal func getPendingTaskTaskById(_ taskId: Double) throws -> PendingTask? {
        guard let persistedPendingTask = try getTaskByTaskId(taskId) else {
            return nil
        }
        let pendingTaskFactory: PendingTasksFactory = PendingTasks.sharedInstance.pendingTasksFactory

        var pendingTask: PendingTask = pendingTaskFactory.getTask(tag: persistedPendingTask.tag!)
        pendingTask.populate(from: persistedPendingTask)
        return pendingTask
    }

    internal func deleteTask(_ taskId: Double) throws {
        let context = CoreDataManager.sharedInstance.viewContext
        if let persistedPendingTask = try getTaskByTaskId(taskId) {
            context.delete(persistedPendingTask)
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

        let pendingTaskFactory: PendingTasksFactory = PendingTasks.sharedInstance.pendingTasksFactory
        var pendingTask: PendingTask = pendingTaskFactory.getTask(tag: persistedPendingTask.tag!)
        pendingTask.populate(from: persistedPendingTask)

        return pendingTask
    }

}
