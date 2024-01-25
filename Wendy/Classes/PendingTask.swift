import Foundation

public struct PendingTask {
    public let tag: String
    public let taskId: Double? // populated later
    public let dataId: String?
    public let groupId: String?
    public let createdAt: Date? // populated later
    
    internal static func from(persistedPendingTask: PersistedPendingTask) -> PendingTask {
        return PendingTask(tag: persistedPendingTask.tag!, taskId: persistedPendingTask.id, dataId: persistedPendingTask.dataId, groupId: persistedPendingTask.groupId, createdAt: persistedPendingTask.createdAt)
    }
        
    public init(tag: String, taskId: Double?, dataId: String?, groupId: String?, createdAt: Date?) {
        self.tag = tag
        self.taskId = taskId
        self.dataId = dataId
        self.groupId = groupId
        self.createdAt = createdAt
    }
}
