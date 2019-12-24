//
//  WendyUIBackgroundFetchResult+Testing.swift
//  Wendy
//
//  Created by Levi Bostian on 12/23/19.
//

import Foundation

public extension WendyUIBackgroundFetchResult {
    static var testing: Testing {
        return Testing()
    }

    class Testing {
        public func get(runnerResult: PendingTasksRunnerResult) -> WendyUIBackgroundFetchResult {
            return WendyUIBackgroundFetchResult(taskRunnerResult: runnerResult, backgroundFetchResult: runnerResult.backgroundFetchResult)
        }
    }
}
