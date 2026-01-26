import Foundation

/// A data structure that both the queue writer and queue readers use together. It's a cache of the queue that is stored on the file system.
protocol FileSystemQueue {
    var queue: [PendingTask] { get }
    func load() // can be called at anytime to read the queue from file system and store in-memory for speed
    func add(_ pendingTask: PendingTask)
    func delete(_ pendingTask: PendingTask)
    func delete(_ taskId: Double)
}

// sourcery: InjectRegister = "FileSystemQueue"
class FileSystemQueueImpl: FileSystemQueue {
    private let fileStore: FileSystemStore
    private let queueFilePath: [String] = ["tasks_queue.json"]
    private let jsonAdapter: JsonAdapter

    init(fileStore: FileSystemStore, jsonAdapter: JsonAdapter) {
        self.fileStore = fileStore
        self.jsonAdapter = jsonAdapter
    }

    func load() {
        dataStore.updateDataBlock { data in
            guard !data.hasLoadedCache else {
                return
            }

            let queueData = self.fileStore.readFile(self.queueFilePath)
            guard let queueData else {
                // no queue file exists.
                data.hasLoadedCache = true
                return
            }

            data.cache = jsonAdapter.fromData(queueData)!
            data.hasLoadedCache = true
        }
    }

    var queue: [PendingTask] {
        load()

        return dataStore.getDataSnapshot().cache
    }

    func add(_ pendingTask: PendingTask) {
        load()

        dataStore.updateDataBlock { data in
            data.cache.append(pendingTask)
            fileStore.saveFile(jsonAdapter.toData(data.cache)!, filePath: queueFilePath)
        }
    }

    func delete(_ taskId: Double) {
        load()

        dataStore.updateDataBlock { data in
            data.cache.removeAll { $0.taskId == taskId }
            fileStore.saveFile(jsonAdapter.toData(data.cache)!, filePath: queueFilePath)
        }
    }

    func delete(_ pendingTask: PendingTask) {
        guard let taskId = pendingTask.taskId else {
            return
        }

        delete(taskId)
    }

    struct Data: AutoResettable {
        var hasLoadedCache = false
        var cache: [PendingTask] = []
    }

    final class DataStore: InMemoryDataStore<Data>, Singleton {
        static let shared: DataStore = .init(data: .init())
    }
}
