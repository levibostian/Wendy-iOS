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
            blankPendingTask.taskId = persistedPendingTask.id
            pendingTasks.append(blankPendingTask)
        }

        return pendingTasks
    }
    
//    internal func getTaskById(_ id: Double) throws -> PendingTask? {
//        let context = CoreDataManager.sharedInstance.viewContext
//
//        let pendingTaskFetchRequest: NSFetchRequest<PendingTask> = PendingTask.fetchRequest()
//        pendingTaskFetchRequest.predicate = NSPredicate(format: "id == %f", id)
//
//        let pendingTasks: [PendingTask] = try context.fetch(pendingTaskFetchRequest)
//        return pendingTasks.isEmpty ? nil : pendingTasks[0]
//    }
//
//    internal func getNextTask(_ lastSuccessfulOrFailedTaskId: Double = 0, failedTasksGroups: [String] = []) throws -> PendingTask? {
//        let context = CoreDataManager.sharedInstance.viewContext
//
//        let pendingTaskFetchRequest: NSFetchRequest<PendingTask> = PendingTask.fetchRequest()
//        if failedTasksGroups.isEmpty {
//            pendingTaskFetchRequest.predicate = NSPredicate(format: "id > %f", lastSuccessfulOrFailedTaskId)
//        } else {
//            pendingTaskFetchRequest.predicate = NSPredicate(format: "(id > %f) AND ((groupId == nil) OR NOT (groupId in \(failedTasksGroups))", lastSuccessfulOrFailedTaskId)
//        }
//        pendingTaskFetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PendingTask.createdAt), ascending: true)]
//
//        let pendingTasks: [PendingTask] = try context.fetch(pendingTaskFetchRequest)
//        return pendingTasks.isEmpty ? nil : pendingTasks[0]
//    }
//
//    internal func deleteTask(_ task: PendingTask) {
//        let context = CoreDataManager.sharedInstance.viewContext
//
//        context.delete(task)
//        CoreDataManager.sharedInstance.saveContext()
//    }

}
