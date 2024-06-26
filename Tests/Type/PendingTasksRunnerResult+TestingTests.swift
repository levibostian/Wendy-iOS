@testable import Wendy
import XCTest

class PendingTasksRunnerResultTestingTests: XCTestCase {
    func test_givenEmptyResults_expectSameInstanceAsConstructor() {
        let actual = PendingTasksRunnerResult.testing.result(from: [])

        XCTAssertTrue(actual.runResults.isEmpty)
    }

    func test_givenResults_expectSameInstanceAsConstructor() {
        let actual = PendingTasksRunnerResult.testing.result(from: [
            TaskRunResult.cancelled
        ])

        XCTAssertEqual(actual.runResults.count, 1)
    }
}
