import Foundation

public extension PendingTasksRunnerResult {
    static var testing: Testing {
        Testing()
    }

    class Testing {
        public func result(from results: [TaskRunResult]) -> PendingTasksRunnerResult {
            PendingTasksRunnerResult.new(results: results)
        }
    }
}
