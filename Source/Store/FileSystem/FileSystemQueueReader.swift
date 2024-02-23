//
//  FileSystemQueueReader.swift
//  Wendy
//
//  Created by Levi Bostian on 2/3/24.
//

import Foundation

// sourcery: InjectRegister = "QueueReader"
// sourcery: InjectSingleton
public class FileSystemQueueReader: QueueReader {
    
    private let queue: FileSystemQueue
    
    init(queue: FileSystemQueue) {
        self.queue = queue
    }
    
    public func getAllTasks() -> [PendingTask] {
        return queue.queue
    }
    
    public func getTaskByTaskId(_ taskId: Double) -> PendingTask? {
        return queue.queue.first(where: { $0.taskId == taskId })
    }
    
    public func getNextTaskToRun(_ lastSuccessfulOrFailedTaskId: Double, filter: RunAllTasksFilter?) -> PendingTask? {
        var potentialTasksToRun = queue.queue
        potentialTasksToRun = potentialTasksToRun.filter {
            guard let taskId = $0.taskId else { return false }
            return taskId > lastSuccessfulOrFailedTaskId
        }
        
        if let filter = filter {
            switch filter {
            case .group(let groupId):
                potentialTasksToRun = potentialTasksToRun.filter {
                    $0.groupId == groupId
                }
            }
        }
        
        return potentialTasksToRun.first
    }
}
