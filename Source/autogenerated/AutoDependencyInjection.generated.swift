// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
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

        _ = self.jsonAdapter
        countDependenciesResolved += 1

        _ = self.pendingTasksManager
        countDependenciesResolved += 1

        _ = self.sharedPendingTasksRunner
        countDependenciesResolved += 1

        return countDependenciesResolved    
    }

    // Convenient function that resets the state of all singletons in the codebase. Use in tests. 
    internal func resetSingletons() {
        DIGraph.DataStore.shared.reset()
        FileSystemQueueImpl.DataStore.shared.reset()
        Mutex.Store.shared.reset()
        PendingTasksManager.DataStore.shared.reset()
        PendingTasksRunner.shared.reset()
        PendingTasksRunner.DataStore.shared.reset()
        Wendy.shared.reset()
        Wendy.DataStore.shared.reset()
        WendyConfig.DataStore.shared.reset()
    }

    // FileSystemStore
    internal var fileSystemStore: FileSystemStore {  
        // First, see if there is an override for this instance.
        let existingOverrides = self.dataStore.getDataSnapshot()
        if let overriddenInstance = existingOverrides.overrides[String(describing: FileSystemStore.self)] as? FileSystemStore {
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
        self.dataStore.updateDataBlock { data in
            data.overrides[String(describing: instance)] = instance
        }
    }
    // FileSystemQueue
    internal var fileSystemQueue: FileSystemQueue {  
        // First, see if there is an override for this instance.
        let existingOverrides = self.dataStore.getDataSnapshot()
        if let overriddenInstance = existingOverrides.overrides[String(describing: FileSystemQueue.self)] as? FileSystemQueue {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.newFileSystemQueue
    }
    private var newFileSystemQueue: FileSystemQueue {    
        return FileSystemQueueImpl(fileStore: self.fileSystemStore, jsonAdapter: self.jsonAdapter)
    }
    // Call this function to override the instance of FileSystemQueue in the graph.
    internal func overrideFileSystemQueue(_ instance: FileSystemQueue) {
        self.dataStore.updateDataBlock { data in
            data.overrides[String(describing: instance)] = instance
        }
    }
    // QueueReader
    public var queueReader: QueueReader {  
        // First, see if there is an override for this instance.
        let existingOverrides = self.dataStore.getDataSnapshot()
        if let overriddenInstance = existingOverrides.overrides[String(describing: QueueReader.self)] as? QueueReader {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.newQueueReader
    }
    private var newQueueReader: QueueReader {    
        return FileSystemQueueReader(queue: self.fileSystemQueue)
    }
    // Call this function to override the instance of QueueReader in the graph.
    internal func overrideQueueReader(_ instance: QueueReader) {
        self.dataStore.updateDataBlock { data in
            data.overrides[String(describing: instance)] = instance
        }
    }
    // QueueWriter
    public var queueWriter: QueueWriter {  
        // First, see if there is an override for this instance.
        let existingOverrides = self.dataStore.getDataSnapshot()
        if let overriddenInstance = existingOverrides.overrides[String(describing: QueueWriter.self)] as? QueueWriter {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.newQueueWriter
    }
    private var newQueueWriter: QueueWriter {    
        return FileSystemQueueWriter(queue: self.fileSystemQueue, jsonAdapter: self.jsonAdapter)
    }
    // Call this function to override the instance of QueueWriter in the graph.
    internal func overrideQueueWriter(_ instance: QueueWriter) {
        self.dataStore.updateDataBlock { data in
            data.overrides[String(describing: instance)] = instance
        }
    }
    // JsonAdapter
    internal var jsonAdapter: JsonAdapter {  
        // First, see if there is an override for this instance.
        let existingOverrides = self.dataStore.getDataSnapshot()
        if let overriddenInstance = existingOverrides.overrides[String(describing: JsonAdapter.self)] as? JsonAdapter {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.newJsonAdapter
    }
    private var newJsonAdapter: JsonAdapter {    
        return JsonAdapterImpl()
    }
    // Call this function to override the instance of JsonAdapter in the graph.
    internal func overrideJsonAdapter(_ instance: JsonAdapter) {
        self.dataStore.updateDataBlock { data in
            data.overrides[String(describing: instance)] = instance
        }
    }
    // PendingTasksManager
    internal var pendingTasksManager: PendingTasksManager {  
        // First, see if there is an override for this instance.
        let existingOverrides = self.dataStore.getDataSnapshot()
        if let overriddenInstance = existingOverrides.overrides[String(describing: PendingTasksManager.self)] as? PendingTasksManager {
            return overriddenInstance
        }
        // If no override, get the instance from the graph.
        return self.newPendingTasksManager
    }
    private var newPendingTasksManager: PendingTasksManager {    
        return PendingTasksManager(queueWriter: self.queueWriter)
    }
    // Call this function to override the instance of PendingTasksManager in the graph.
    internal func overridePendingTasksManager(_ instance: PendingTasksManager) {
        self.dataStore.updateDataBlock { data in
            data.overrides[String(describing: instance)] = instance
        }
    }
    // PendingTasksRunner (singleton)
    // Singletons cannot be injected in the constructor of an object. A property getter is the preferred pattern to use to get a singleton instance in your class:
    // `var foo: Foo { inject.sharedFoo }`
    // This is to avoid bugs. If you inject in the constructor, you will not get the singleton instance, you will get a copy of the singleton instance.
     var sharedPendingTasksRunner: PendingTasksRunner {   
        if let overriddenInstance = dataStore.getDataSnapshot().overrides[String(describing: PendingTasksRunner.self)] as? PendingTasksRunner {
            return overriddenInstance
        }
        return PendingTasksRunner.shared
    }
    // Call this function to override the instance of PendingTasksRunner in the graph.
    internal func overridePendingTasksRunner(_ instance: PendingTasksRunner) {
        self.dataStore.updateDataBlock { data in
            data.overrides[String(describing: instance)] = instance
        }
    }
}

// swiftlint:enable all