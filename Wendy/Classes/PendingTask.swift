import Foundation

public struct PendingTask: Codable {
    public let tag: String
    public let taskId: Double? // populated later
    public let dataId: String?
    public let groupId: String?
    public let createdAt: Date? // populated later
        
    public init(tag: String, taskId: Double?, dataId: String?, groupId: String?, createdAt: Date?) {
        self.tag = tag
        self.taskId = taskId
        self.dataId = dataId
        self.groupId = groupId
        self.createdAt = createdAt
    }
}
