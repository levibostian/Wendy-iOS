import Foundation

public struct PendingTask: Codable, Sendable {
    public let tag: String
    public let taskId: Double? // populated later
    public let data: Data?
    public let groupId: String?
    public let createdAt: Date? // populated later

    public init(tag: String, taskId: Double?, data: Data?, groupId: String?, createdAt: Date?) {
        self.tag = tag
        self.taskId = taskId
        self.data = data
        self.groupId = groupId
        self.createdAt = createdAt
    }
}
