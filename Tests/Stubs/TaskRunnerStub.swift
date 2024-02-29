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
    var runTaskClosure: ((String, String?, @escaping (Error?) -> Void) -> Void)? = nil
    
    func runTask(tag: String, dataId: String?, complete: @escaping (Error?) -> Void) {
        if let runTaskClosure {
            runTaskClosure(tag, dataId, complete)
            return
        }
        
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
