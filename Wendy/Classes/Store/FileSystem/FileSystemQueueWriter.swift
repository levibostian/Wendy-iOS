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
    
    public func add(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        // TODO:
        return PendingTask(tag: tag, taskId: nil, dataId: nil, groupId: nil, createdAt: nil)
    }
    
    public func delete(taskId: Double) -> Bool {
        // TODO:
        return false
    }
}
