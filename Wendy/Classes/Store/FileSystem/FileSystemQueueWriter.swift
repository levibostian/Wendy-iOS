//
//  FileSystemQueueWriter.swift
//  Wendy
//
//  Created by Levi Bostian on 1/27/24.
//

import Foundation

// A writer, that stores data in the form of files on the file system.
public class FileSystemQueueWriter: QueueWriter {
    
    private let fileStore: FileSystemStore = FileManagerFileSystemStore()
    
    private var queueCache: [PendingTask] = [] // TODO: implement a real cache
    
    private let queueCacheFilePath: [String] = ["tasks_queue.json"]
    
    public func add(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        // TODO: mutex the queue cache
        
        let newTaskId = PendingTasksUtil.getNextPendingTaskId() // same that the coredata store uses.
        let newCreatedAt = Date()
        let newPendingTask = PendingTask(tag: tag, taskId: newTaskId, dataId: dataId, groupId: groupId, createdAt: newCreatedAt)
        
        let jsonStringPendingTask = JsonAdapterImpl.shared.toData(newPendingTask)!
        
        queueCache.append(newPendingTask)
        
        fileStore.saveFile(JsonAdapterImpl.shared.toData(queueCache)!, filePath: queueCacheFilePath)
        
        return newPendingTask
    }
    
    public func delete(taskId: Double) -> Bool {
        // TODO: mutex the queue cache

        queueCache.removeAll { $0.taskId == taskId }
        fileStore.saveFile(JsonAdapterImpl.shared.toData(queueCache)!, filePath: queueCacheFilePath)
        
        return false
    }
}
