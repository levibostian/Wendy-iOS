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
    
    func runTask(tag: String, dataId: String?, complete: @escaping (Error?) -> Void) {
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
