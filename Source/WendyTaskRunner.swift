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
    func runTask(tag: String, dataId: String?) async throws
}

public protocol WendyTaskRunner {
    func runTask(tag: String, dataId: String?, complete: @escaping (Error?) -> Void)
}

// Adapter for us to just use WendyTaskRunnerConcurrency in the internal code rather then having to deal with 2 protocols.
internal class LegayTaskRunnerAdapter: WendyTaskRunnerConcurrency {
    private let taskRunner: WendyTaskRunner
    
    init(taskRunner: WendyTaskRunner) {
        self.taskRunner = taskRunner
    }
    
    public func runTask(tag: String, dataId: String?) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            taskRunner.runTask(tag: tag, dataId: dataId) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
