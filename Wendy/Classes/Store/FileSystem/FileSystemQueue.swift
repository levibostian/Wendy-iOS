//
//  FileSystemQueueCache.swift
//  Wendy
//
//  Created by Levi Bostian on 1/27/24.
//

import Foundation

// A data structure that both the queue writer and queue readers use together. It's a cache of the queue that is stored on the file system.
internal protocol FileSystemQueue {
    var queue: [PendingTask] { get }
    func load() // can be called at anytime to read the queue from file system and store in-memory for speed
    func add(_ pendingTask: PendingTask)
    func delete(_ pendingTask: PendingTask)
    func delete(_ taskId: Double)
}

internal class FileSystemQueueImpl: FileSystemQueue {
    
    internal static let shared = FileSystemQueueImpl()
    
    private let fileStore: FileSystemStore = FileManagerFileSystemStore()
    private let queueFilePath: [String] = ["tasks_queue.json"]
    
    private let mutex = Mutex()
    
    private var hasLoadedCache = false
    private var cache: [PendingTask] = []
    
    func load() {
        mutex.lock()
        defer { mutex.unlock() }
        
        guard !hasLoadedCache else {
            return
        }
        
        let queueData = fileStore.readFile(queueFilePath)
        guard let queueData = queueData else {
            // no queue file exists.
            hasLoadedCache = true
            return
        }
        
        cache = JsonAdapterImpl.shared.fromData(queueData)!
        hasLoadedCache = true
    }
    
    var queue: [PendingTask] {
        return cache
    }
    
    func add(_ pendingTask: PendingTask) {
        mutex.lock()
        defer { mutex.unlock() }
        
        load()
        cache.append(pendingTask)
        
        fileStore.saveFile(JsonAdapterImpl.shared.toData(cache)!, filePath: queueFilePath)
    }
    
    func delete(_ taskId: Double) {
        mutex.lock()
        defer { mutex.unlock() }
        
        load()
        cache.removeAll { $0.taskId == taskId }
        
        fileStore.saveFile(JsonAdapterImpl.shared.toData(cache)!, filePath: queueFilePath)
    }
    
    func delete(_ pendingTask: PendingTask) {
        guard let taskId = pendingTask.taskId else {
            return
        }
        
        self.delete(taskId)
    }
}
