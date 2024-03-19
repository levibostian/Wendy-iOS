//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/11/24.
//

import Foundation
@testable import Wendy

class TaskRunnerStub: WendyTaskRunner {
    
    @Atomic var resultsQueue: [Result<Void?, Error>] = []
    var runTaskClosure: ((String, String?) async throws -> Void)? = nil
    
    func runTask(tag: String, dataId: String?, complete: @escaping (Error?) -> Void) {
        // there are 2 ways for stub to run a task.
        
        // First, check if there is a closure that implements the function body.
        if let runTaskClosure {
            Task {
                do {
                    try await runTaskClosure(tag, dataId)
                    complete(nil)
                } catch {
                    complete(error)
                }
                
                return
            }
        } else {
            // Otherwise, process the queue of return results.
            let result = resultsQueue.removeFirst()
            
            switch result {
                case .success:
                    complete(nil)
                    break
                case .failure(let error):
                    complete(error)
                    break
            }
        }
    }
}
