//
//  WendyTaskRunner.swift
//  Wendy
//
//  Created by Levi Bostian on 1/14/24.
//

import Foundation

/// Version of the Task runner that uses Swift Concurrency.
/// In the future, this protocol may replace the default one.
public protocol WendyTaskRunnerConcurrency {
    func runTask(tag: String, data: Data?) async throws
}

public protocol WendyTaskRunner {
    func runTask(tag: String, data: Data?, complete: @Sendable @escaping (Error?) -> Void)
}

// MARK: backwards compatibility, non-async runner

// Adapter for us to just use WendyTaskRunnerConcurrency in the internal code rather then having to deal with 2 protocols.
internal class LegacyTaskRunnerAdapter: WendyTaskRunnerConcurrency {
    private let taskRunner: WendyTaskRunner
    
    init(taskRunner: WendyTaskRunner) {
        self.taskRunner = taskRunner
    }
    
    func runTask(tag: String, data: Data?) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            taskRunner.runTask(tag: tag, data: data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
