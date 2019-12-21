//
//  PendingTasksRunnerResult.swift
//  Wendy
//
//  Created by Levi Bostian on 12/21/19.
//

import Foundation

public struct PendingTasksRunnerResult {
    let numberTasksRun: Int
    let numberSuccessfulTasks: Int
    let numberFailedTasks: Int
    let numberSkippedTasks: Int
    let runResults: [TaskRunResult]
    
    static func new() -> PendingTasksRunnerResult {
        return PendingTasksRunnerResult(numberTasksRun: 0, numberSuccessfulTasks: 0, numberFailedTasks: 0, numberSkippedTasks: 0, runResults: [])
    }
    
    func addResult(_ runResult: TaskRunResult) -> PendingTasksRunnerResult {
        var numberSuccessfulTasks = self.numberSuccessfulTasks
        var numberFailedTasks = self.numberFailedTasks
        var numberSkippedTasks = self.numberSkippedTasks
        var runResults = self.runResults
        
        switch runResult {
        case .successful:
            numberSuccessfulTasks += 1
        case .failure:
            numberFailedTasks += 1
        case .skipped:
            numberSkippedTasks += 1
        }
        
        runResults.append(runResult)
        
        return PendingTasksRunnerResult(numberTasksRun: runResults.count, numberSuccessfulTasks: numberSuccessfulTasks, numberFailedTasks: numberFailedTasks, numberSkippedTasks: numberSkippedTasks, runResults: runResults)
    }
}
