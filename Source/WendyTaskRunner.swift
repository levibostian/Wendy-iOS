import Foundation

public protocol WendyTaskRunner {
    func runTask(tag: String, data: Data?) async throws
}
