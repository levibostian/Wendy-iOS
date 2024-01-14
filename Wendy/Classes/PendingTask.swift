import Foundation

public struct PendingTask {
    public let tag: String
    public let taskId: Double? // populated later
    public let dataId: String?
    public let groupId: String?
    public let createdAt: Date? // populated later
    
    internal static func nonPersisted(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        return PendingTask(tag: tag, taskId: nil, dataId: dataId, groupId: groupId, createdAt: nil)
    }
    
    internal static func persisted(_ persistedPendingTask: PersistedPendingTask) -> PendingTask {
        return PendingTask(tag: persistedPendingTask.tag!, taskId: persistedPendingTask.id, dataId: persistedPendingTask.dataId, groupId: persistedPendingTask.groupId, createdAt: persistedPendingTask.createdAt)
    }
    
    internal func from(persistedPendingTask: PersistedPendingTask) -> PendingTask {
        return PendingTask(tag: self.tag, taskId: persistedPendingTask.id, dataId: self.dataId, groupId: self.groupId, createdAt: persistedPendingTask.createdAt)
    }
}
