//
//  FileSystemQueueWriter.swift
//  Wendy
//
//  Created by Levi Bostian on 1/27/24.
//

import Foundation

// Note: This class is currently not being used in the codebase. After all filesystem code is written, it can be hooked up to the rest of Wendy to enable it.

// A writer, that stores data in the form of files on the file system.
public class FileSystemQueueWriter: QueueWriter {
    
    @Atomic public private(set) static var shared = FileSystemQueueWriter()
    
    internal static func reset() { // for tests
        Self.shared = FileSystemQueueWriter()
    }
    
    private let mutex = Mutex()
    
    private init() {}

    private var queue: FileSystemQueue {
        return FileSystemQueueImpl.shared
    }
    
    public func add(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        mutex.lock()
        defer { mutex.unlock() }
        
        let newTaskId = PendingTasksUtil.getNextPendingTaskId() // same that the coredata store uses.
        let newCreatedAt = Date()
        let newPendingTask = PendingTask(tag: tag, taskId: newTaskId, dataId: dataId, groupId: groupId, createdAt: newCreatedAt)
        
        queue.add(newPendingTask)
        
        return newPendingTask
    }
    
    public func delete(taskId: Double) -> Bool {
        mutex.lock()
        defer { mutex.unlock() }
        
        queue.delete(taskId)
        
        return false
    }
}
