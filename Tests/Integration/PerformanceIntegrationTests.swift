import Foundation
@testable import Wendy
import XCTest

class PerformanceIntegrationTests: TestClass {
    private var taskRunnerStub: TaskRunnerStub!

    override func setUp() {
        super.setUp()

        taskRunnerStub = TaskRunnerStub()

        Wendy.setup(taskRunner: taskRunnerStub)
    }

    // MARK: threading

    func test_threading_givenAddTasksInDifferentThreads_expectAllGetAddedAndRun() async {
        let expectToAddTasks = expectation(description: "expect to add tasks")
        expectToAddTasks.expectedFulfillmentCount = 2

        Task {
            Wendy.shared.addTask(tag: "tag", data: "dataId")
            expectToAddTasks.fulfill()
        }

        Task {
            Wendy.shared.addTask(tag: "tag", data: "dataId")
            expectToAddTasks.fulfill()
        }

        await fulfillment(of: [expectToAddTasks], timeout: 1.0)

        taskRunnerStub.resultsQueue = [
            .success(nil),
            .success(nil)
        ]

        let runTasksResults = await runAllTasks()
        XCTAssertEqual(runTasksResults.numberTasksRun, 2)
    }

    // Wendy has the ability to run a single task whenever you want. So if wendy is running 100 tasks, for example, you can run a single task and not have to wait for wendy to finish running the rest of the 100 tasks.
    func test_runTask_givenAlreadyRunningAllTasks_expectBeAbleToRunSingleTaskInMiddleOfRunningAll() async {
        _ = Wendy.shared.addTask(tag: "task1", data: "dataId")
        _ = Wendy.shared.addTask(tag: "task2", data: "dataId")
        _ = Wendy.shared.addTask(tag: "task3", data: "dataId")

        let expectToRunTask1 = expectation(description: "expect to run task 1")
        let expectToRunTask3 = expectation(description: "expect to run task 3")
        let expectToFinishRunningSingleTask = expectation(description: "expect to finish running single task")
        let expectToRunTask2 = expectation(description: "expect to run task 2")
        let expectToFinishRuningAllTasks = expectation(description: "expect to finish running all tasks")

        taskRunnerStub.runTaskClosure = { tagOfTaskWeAreRunning, _ in
            // When we begin running all tasks, ask Wendy to run task 3, which means it would run it before task 2.
            if tagOfTaskWeAreRunning == "task1" {
                // Start a new task so the closure can finish executing. Deadlock happens if we dont do this.
                // To avoid flakiness, we need to increase changes of Task executing before the closure finishes and task 2 starts before task 3.
                // We increase changes of Task executing by setting the priority high and yielding the closure's Task.
                Task(priority: .high) {
                    _ = await Wendy.shared.runTask(3)
                    expectToFinishRunningSingleTask.fulfill()
                }

                await Task.yield()
            }

            if tagOfTaskWeAreRunning == "task1" {
                expectToRunTask1.fulfill()
            } else if tagOfTaskWeAreRunning == "task2" {
                expectToRunTask2.fulfill()
            } else if tagOfTaskWeAreRunning == "task3" {
                expectToRunTask3.fulfill()
            }
        }

        await Wendy.shared.runTasks()
        expectToFinishRuningAllTasks.fulfill()

        await fulfillment(of: [
            expectToRunTask1,
            expectToRunTask3,
            expectToFinishRunningSingleTask,
            expectToRunTask2,
            expectToFinishRuningAllTasks
        ], timeout: 1.0, enforceOrder: true)
    }

    func test_runAllTasks_givenAlreadyRunning_expectIgnoreRequest() async {
        let expectToFinishRunningAllTasks = expectation(description: "expect to finish running all tasks")
        let expectToIgnoreRequestToRunAllTasks = expectation(description: "expect to ignore request to run all tasks")

        _ = Wendy.shared.addTask(tag: "task1", data: "dataId")
        _ = Wendy.shared.addTask(tag: "task2", data: "dataId")

        taskRunnerStub.runTaskClosure = { tagOfTaskWeAreRunning, _ in
            // When we begin running all tasks, ask Wendy to run all tasks again. The request should be ignored so it should complete fast.
            if tagOfTaskWeAreRunning == "task1" {
                Task {
                    _ = await Wendy.shared.runTasks()
                    expectToIgnoreRequestToRunAllTasks.fulfill()
                }
            }
        }

        await Wendy.shared.runTasks()
        expectToFinishRunningAllTasks.fulfill()

        await fulfillment(of: [
            expectToIgnoreRequestToRunAllTasks,
            expectToFinishRunningAllTasks
        ], timeout: 1.0, enforceOrder: true)
    }
}
