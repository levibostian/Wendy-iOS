// Generated using Sourcery 2.1.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable all

import Foundation

/**
######################################################
Documentation
######################################################

This automatically generated file you are viewing is a dependency injection graph for your app's source code.
You may be wondering a couple of questions. 

1. How did this file get generated? Answer --> https://github.com/levibostian/Sourcery-DI#how
2. Why use this dependency injection graph instead of X other solution/tool? Answer --> https://github.com/levibostian/Sourcery-DI#why-use-this-project
3. How do I add dependencies to this graph file? Follow one of the instructions below:
* Add a non singleton class: https://github.com/levibostian/Sourcery-DI#add-a-non-singleton-class
* Add a generic class: https://github.com/levibostian/Sourcery-DI#add-a-generic-class
* Add a singleton class: https://github.com/levibostian/Sourcery-DI#add-a-singleton-class
* Add a class from a 3rd party library/SDK: https://github.com/levibostian/Sourcery-DI#add-a-class-from-a-3rd-party
* Add a `typealias` https://github.com/levibostian/Sourcery-DI#add-a-typealias

4. How do I get dependencies from the graph in my code? 
```
// If you have a class like this:
class OffRoadWheels {}

class ViewController: UIViewController {
    // Call the property getter to get your dependency from the graph: 
    let wheels = DIGraph.getInstance(siteId: "").offRoadWheels
    // note the name of the property is name of the class with the first letter lowercase. 
}
```

5. How do I use this graph in my test suite? 
```
let mockOffRoadWheels = // make a mock of OffRoadWheels class 
DIGraph().override(mockOffRoadWheels, OffRoadWheels.self) 
```

Then, when your test function finishes, reset the graph:
```
DIGraph().reset()
```

*/



extension DIGraph {
    // call in automated test suite to confirm that all dependnecies able to resolve and not cause runtime exceptions. 
    // internal scope so each module can provide their own version of the function with the same name. 
    internal func testDependenciesAbleToResolve() -> Int {
        var countDependenciesResolved = 0

        _ = self.fileSystemStore
        countDependenciesResolved += 1

        _ = self.fileSystemQueue
        countDependenciesResolved += 1

        _ = self.queueReader
        countDependenciesResolved += 1

        _ = self.queueWriter
        countDependenciesResolved += 1

        _ = self.pendingTasksManager
        countDependenciesResolved += 1

        _ = self.pendingTasksRunner
        countDependenciesResolved += 1

        return countDependenciesResolved    
    }

    // FileSystemStore
    internal var fileSystemStore: FileSystemStore {  
        // First, see if there is an override for this instance.
        if let overriddenInstance = overrides[String(describing: FileSystemStore.self)] as? FileSystemStore {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.newFileSystemStore
    }
    private var newFileSystemStore: FileSystemStore {    
        return FileManagerFileSystemStore()
    }
    // Call this function to override the instance of FileSystemStore in the graph.
    internal func overrideFileSystemStore(_ instance: FileSystemStore) {
        self.overrides[String(describing: instance)] = instance
    }
    // FileSystemQueue (singleton)
    internal var fileSystemQueue: FileSystemQueue {  
        // First, see if there is an override for this instance.
        if let overriddenInstance = overrides[String(describing: FileSystemQueue.self)] as? FileSystemQueue {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.sharedFileSystemQueue
    }
    private var sharedFileSystemQueue: FileSystemQueue {
        mutex.lock()
        if let existingSingleton = singletons[String(describing: FileSystemQueue.self)] as? FileSystemQueue {
            mutex.unlock()
            return existingSingleton
        }
        let newInstance = newFileSystemQueue
        singletons[String(describing: FileSystemQueue.self)] = newInstance
        mutex.unlock()

        return newInstance
    }
    private var newFileSystemQueue: FileSystemQueue {
        return FileSystemQueueImpl(fileStore: self.fileSystemStore)
    }
    // Call this function to override the instance of FileSystemQueue in the graph.
    internal func overrideFileSystemQueue(_ instance: FileSystemQueue) {
        self.overrides[String(describing: instance)] = instance
    }
    // QueueReader (singleton)
    public var queueReader: QueueReader {  
        // First, see if there is an override for this instance.
        if let overriddenInstance = overrides[String(describing: QueueReader.self)] as? QueueReader {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.sharedQueueReader
    }
    private var sharedQueueReader: QueueReader {
        mutex.lock()
        if let existingSingleton = singletons[String(describing: QueueReader.self)] as? QueueReader {
            mutex.unlock()
            return existingSingleton
        }
        let newInstance = newQueueReader
        singletons[String(describing: QueueReader.self)] = newInstance
        mutex.unlock()

        return newInstance
    }
    private var newQueueReader: QueueReader {
        return FileSystemQueueReader(queue: self.fileSystemQueue)
    }
    // Call this function to override the instance of QueueReader in the graph.
    internal func overrideQueueReader(_ instance: QueueReader) {
        self.overrides[String(describing: instance)] = instance
    }
    // QueueWriter (singleton)
    public var queueWriter: QueueWriter {  
        // First, see if there is an override for this instance.
        if let overriddenInstance = overrides[String(describing: QueueWriter.self)] as? QueueWriter {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.sharedQueueWriter
    }
    private var sharedQueueWriter: QueueWriter {
        mutex.lock()
        if let existingSingleton = singletons[String(describing: QueueWriter.self)] as? QueueWriter {
            mutex.unlock()
            return existingSingleton
        }
        let newInstance = newQueueWriter
        singletons[String(describing: QueueWriter.self)] = newInstance
        mutex.unlock()

        return newInstance
    }
    private var newQueueWriter: QueueWriter {
        return FileSystemQueueWriter(queue: self.fileSystemQueue)
    }
    // Call this function to override the instance of QueueWriter in the graph.
    internal func overrideQueueWriter(_ instance: QueueWriter) {
        self.overrides[String(describing: instance)] = instance
    }
    // PendingTasksManager (singleton)
    internal var pendingTasksManager: PendingTasksManager {  
        // First, see if there is an override for this instance.
        if let overriddenInstance = overrides[String(describing: PendingTasksManager.self)] as? PendingTasksManager {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.sharedPendingTasksManager
    }
    private var sharedPendingTasksManager: PendingTasksManager {
        mutex.lock()
        if let existingSingleton = singletons[String(describing: PendingTasksManager.self)] as? PendingTasksManager {
            mutex.unlock()
            return existingSingleton
        }
        let newInstance = newPendingTasksManager
        singletons[String(describing: PendingTasksManager.self)] = newInstance
        mutex.unlock()

        return newInstance
    }
    private var newPendingTasksManager: PendingTasksManager {
        return PendingTasksManager(queueWriter: self.queueWriter, queueReader: self.queueReader)
    }
    // Call this function to override the instance of PendingTasksManager in the graph.
    internal func overridePendingTasksManager(_ instance: PendingTasksManager) {
        self.overrides[String(describing: instance)] = instance
    }
    // PendingTasksRunner (singleton)
    internal var pendingTasksRunner: PendingTasksRunner {  
        // First, see if there is an override for this instance.
        if let overriddenInstance = overrides[String(describing: PendingTasksRunner.self)] as? PendingTasksRunner {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.sharedPendingTasksRunner
    }
    private var sharedPendingTasksRunner: PendingTasksRunner {
        mutex.lock()
        if let existingSingleton = singletons[String(describing: PendingTasksRunner.self)] as? PendingTasksRunner {
            mutex.unlock()
            return existingSingleton
        }
        let newInstance = newPendingTasksRunner
        singletons[String(describing: PendingTasksRunner.self)] = newInstance
        mutex.unlock()

        return newInstance
    }
    private var newPendingTasksRunner: PendingTasksRunner {
        return PendingTasksRunner(pendingTasksManager: self.pendingTasksManager)
    }
    // Call this function to override the instance of PendingTasksRunner in the graph.
    internal func overridePendingTasksRunner(_ instance: PendingTasksRunner) {
        self.overrides[String(describing: instance)] = instance
    }
}

// swiftlint:enable all