//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/11/24.
//

import Foundation
@testable import Wendy

final class TaskRunnerStub: WendyTaskRunner, Sendable {
    
    let _resultsQueue: MutableSendable<[Result<Void?, Error>]> = MutableSendable([])
    let _runTaskClosure: MutableSendable<((String, String?) async throws -> Void)?> = MutableSendable(nil)
    
    var resultsQueue: [Result<Void?, Error>] {
        get { _resultsQueue.get() }
        set { _resultsQueue.set(newValue) }
    }
    var runTaskClosure: ((String, String?) async throws -> Void)? {
        get { _runTaskClosure.get() }
        set { _runTaskClosure.set(newValue) }
    }
    
    func runTask(tag: String, dataId: String?, complete: @Sendable @escaping (Error?) -> Void) {
        Task {
            do {
                try await runTask(tag: tag, dataId: dataId)
                complete(nil)
            } catch {
                complete(error)
            }
        }
    }
    
    private func runTask(tag: String, dataId: String?) async throws {
        // there are 2 ways for stub to run a task.
        
        // First, check if there is a closure that implements the function body.
        if let runTaskClosure {
            try await runTaskClosure(tag, dataId)
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
