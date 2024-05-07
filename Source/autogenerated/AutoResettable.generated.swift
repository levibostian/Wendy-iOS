// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension DIGraph.Data: Resettable {
    public mutating func reset() {
        let newInstance = Self.init()
        overrides = newInstance.overrides
    }
}
extension FileSystemQueueImpl.Data: Resettable {
    public mutating func reset() {
        let newInstance = Self.init()
        hasLoadedCache = newInstance.hasLoadedCache
        cache = newInstance.cache
    }
}
extension Mutex.Data: Resettable {
    public mutating func reset() {
        let newInstance = Self.init()
        mutexes = newInstance.mutexes
    }
}
extension PendingTasksManager.Data: Resettable {
    public mutating func reset() {
        let newInstance = Self.init()
        queueReaders = newInstance.queueReaders
    }
}
extension PendingTasksRunner.Data: Resettable {
    public mutating func reset() {
        let newInstance = Self.init()
        currentlyRunningTask = newInstance.currentlyRunningTask
    }
}
extension Wendy.InitializedData: Resettable {
    public mutating func reset() {
        let newInstance = Self.init()
        taskRunner = newInstance.taskRunner
    }
}
extension WendyConfig.Data: Resettable {
    public mutating func reset() {
        let newInstance = Self.init()
        logTag = newInstance.logTag
        strict = newInstance.strict
        debug = newInstance.debug
        automaticallyRunTasks = newInstance.automaticallyRunTasks
        taskRunnerListeners = newInstance.taskRunnerListeners
        taskStatusListeners = newInstance.taskStatusListeners
    }
}
