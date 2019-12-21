@testable import Wendy
import XCTest

class PendingTasksRunnerResultTest: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    func test_firstFailedResult_givenEmptyResults_expectNil() {
        let givenResults: [TaskRunResult] = []
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.firstFailedResult

        XCTAssertNil(actual)
    }

    func test_firstFailedResult_givenSuccessful_expectNil() {
        let givenResults: [TaskRunResult] = [
            .successful
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.firstFailedResult

        XCTAssertNil(actual)
    }

    func test_firstFailedResult_givenSuccessfulAndSkipped_expectFirstSkip() {
        let givenResults: [TaskRunResult] = [
            .successful,
            .skipped(reason: .notReadyToRun)
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.firstFailedResult

        XCTAssertNotNil(actual)
    }

    func test_firstFailedResult_givenSuccessfulAndFailed_expectFirstFailure() {
        let givenResults: [TaskRunResult] = [
            .successful,
            .failure(error: ErrorForTesting.foo)
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.firstFailedResult

        XCTAssertNotNil(actual)
    }

    func test_firstFailedResult_givenCancelled_expectNil() {
        let givenResults: [TaskRunResult] = [
            .cancelled
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.firstFailedResult

        XCTAssertNil(actual)
    }

    func test_successful_givenSuccessful_expectTrue() {
        let givenResults: [TaskRunResult] = [
            .successful
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.successful

        XCTAssertTrue(actual)
    }

    func test_successful_givenCancelled_expectTrue() {
        let givenResults: [TaskRunResult] = [
            .cancelled
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.successful

        XCTAssertTrue(actual)
    }

    func test_successful_givenSkipped_expectFalse() {
        let givenResults: [TaskRunResult] = [
            .skipped(reason: .partOfFailedGroup)
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.successful

        XCTAssertFalse(actual)
    }

    func test_successful_givenFailed_expectFalse() {
        let givenResults: [TaskRunResult] = [
            .failure(error: ErrorForTesting.foo)
        ]
        let runnerResult = PendingTasksRunnerResult.new(results: givenResults)

        let actual = runnerResult.successful

        XCTAssertFalse(actual)
    }
}
