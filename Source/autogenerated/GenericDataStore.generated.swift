// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension DIGraph {
    var dataStore: DIGraph.DataStore { .shared }
}
extension FileSystemQueueImpl {
    var dataStore: FileSystemQueueImpl.DataStore { .shared }
}
extension Mutex {
    var dataStore: Mutex.Store { .shared }
}
extension PendingTasksManager {
    var dataStore: PendingTasksManager.DataStore { .shared }
}
extension PendingTasksRunner {
    var dataStore: PendingTasksRunner.DataStore { .shared }
}
extension Wendy {
    var dataStore: Wendy.DataStore { .shared }
}
extension WendyConfig {
    var dataStore: WendyConfig.DataStore { .shared }
}
