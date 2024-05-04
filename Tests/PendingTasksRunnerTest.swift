import Foundation
@testable import Wendy
import XCTest

class PendingTasksRunnerTest: TestClass {
    private var runner: PendingTasksRunner!

    private let taskRunnerStub = TaskRunnerStub()

    override func setUp() {
        super.setUp()

        runner = PendingTasksRunner()
        Wendy.setup(taskRunner: taskRunnerStub)
    }

    // MARK: cancel

    @MainActor // because we have a `Task`, this fixes concurrency warnings in test function.
    func test_givenCancelRunningAllTasks_expectExitBeforeRunningAllTasks() async throws {
        Wendy.shared.addTask(tag: "tag", data: "dataId")
        Wendy.shared.addTask(tag: "tag", data: "dataId")

        var taskToCancel: Task<PendingTasksRunnerResult, Error>!

        taskRunnerStub.runTaskClosure = { _, _ in
            taskToCancel.cancel()
            // because we do not throw in this function, the first task will be successful.
        }

        taskToCancel = Task {
            await runner.runAllTasks(filter: nil)
        }

        let runAllTasksResult = try await taskToCancel.value

        XCTAssertEqual(2, runAllTasksResult.numberTasksRun)
        XCTAssertEqual(1, runAllTasksResult.numberSuccessfulTasks)
        XCTAssertEqual(1, runAllTasksResult.numberCancelledTasks)
    }
}
