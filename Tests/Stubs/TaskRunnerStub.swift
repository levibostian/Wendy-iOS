//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/11/24.
//

import Foundation
@testable import Wendy

class TaskRunnerStub: WendyTaskRunnerConcurrency {
    
    @Atomic var resultsQueue: [Result<Void?, Error>] = []
    var runTaskClosure: ((String, String?) async throws -> Void)? = nil
    
    func runTask(tag: String, dataId: String?) async throws {
        if let runTaskClosure {
            try await runTaskClosure(tag, dataId)
            return
        }
        
        let result = resultsQueue.removeFirst()
        
        switch result {
            case .success:
                return
            case .failure(let error):
                throw error
        }
    }
}
