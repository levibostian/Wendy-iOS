import Foundation

public struct PendingTask {
    let tag: String
    let taskId: Double? // populated later
    let dataId: String?
    let groupId: String?
    let createdAt: Date? // populated later
    
    internal static func nonPersisted(tag: String, dataId: String?, groupId: String?) -> PendingTask {
        return PendingTask(tag: tag, taskId: nil, dataId: dataId, groupId: groupId, createdAt: nil)
    }
    
    internal func from(persistedPendingTask: PersistedPendingTask) -> PendingTask {
        return PendingTask(tag: self.tag, taskId: persistedPendingTask.id, dataId: self.dataId, groupId: self.groupId, createdAt: persistedPendingTask.createdAt)
    }
}
