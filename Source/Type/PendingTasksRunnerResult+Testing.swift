//
//  PendingTasksRunnerResult+Testing.swift
//  Wendy
//
//  Created by Levi Bostian on 12/23/19.
//

import Foundation

public extension PendingTasksRunnerResult {
    static var testing: Testing {
        return Testing()
    }

    class Testing {
        public func result(from results: [TaskRunResult]) -> PendingTasksRunnerResult {
            return PendingTasksRunnerResult.new(results: results)
        }
    }
}
