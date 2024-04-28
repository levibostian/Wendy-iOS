import Foundation
@testable import Wendy

final class TaskRunnerStub: WendyTaskRunner {
    var resultsQueue: [Result<Void?, Error>] = []
    var runTaskClosure: ((String, Data?) async throws -> Void)?

    public func runTask(tag: String, data: Data?) async throws {
        // there are 2 ways for stub to run a task.

        // First, check if there is a closure that implements the function body.
        if let runTaskClosure {
            try await runTaskClosure(tag, data)
        } else {
            // Otherwise, process the queue of return results.
            let result = resultsQueue.removeFirst()

            switch result {
            case .success:
                break
            case .failure(let error):
                throw error
            }
        }
    }
}
