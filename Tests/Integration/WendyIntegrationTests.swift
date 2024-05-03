import Foundation
@testable import Wendy
import XCTest

class WendyIntegrationTests: TestClass {
    private var taskRunnerStub: TaskRunnerStub!

    override func setUp() {
        super.setUp()

        taskRunnerStub = TaskRunnerStub()

        Wendy.setup(taskRunner: taskRunnerStub)
    }

    // MARK: adding tasks

    func test_addTasks_givenAddTasksWithSameArguments_expectEveryTaskUnique() {
        let task1 = Wendy.shared.addTask(tag: "tag", data: "dataId")
        let task2 = Wendy.shared.addTask(tag: "tag", data: "dataId")

        XCTAssertNotEqual(task1, task2)

        let taskGroup1 = Wendy.shared.addTask(tag: "tag", data: "dataId", groupId: "groupName")
        let taskGroup2 = Wendy.shared.addTask(tag: "tag", data: "dataId", groupId: "groupName")

        XCTAssertNotEqual(taskGroup1, taskGroup2)
    }

    func test_addTasks_expectAddTasksAndRunTasksGivenEnumInsteadOfStrings() async {
        enum AsyncTasks: String {
            case foo
        }

        let givenTag = AsyncTasks.foo

        Wendy.shared.addTask(tag: givenTag, data: "dataId")

        taskRunnerStub.runTaskClosure = { tag, _ in
            let actualTag = AsyncTasks(rawValue: tag)

            XCTAssertEqual(actualTag, givenTag)
        }

        _ = await runAllTasks()
    }

    func test_addTasks_givenProvideCobaleObject_expectGetObjectBackWhenRunTask() async {
        struct CodableObject: Codable {
            let foo: String
            let nested: Nested

            struct Nested: Codable {
                let bar: String
            }
        }

        Wendy.shared.addTask(tag: "foo", data: CodableObject(foo: .random, nested: .init(bar: .random)))

        taskRunnerStub.runTaskClosure = { tag, data in
            switch tag {
            case "foo":
                guard let _: CodableObject = data?.wendyDecode() else {
                    XCTFail("Could not decode data")
                    return
                }
            default:
                XCTFail("Unknown tag")
            }
        }

        _ = await runAllTasks()
    }

    // MARK: run tasks

    func test_runTasks_givenNoTasksAdded_expectRunNoTasks() async {
        let actual = await runAllTasks().numberTasksRun
        XCTAssertEqual(actual, 0)
    }

    func test_runTasks_givenTaskSuccedds_expectDeleteTask() async {
        taskRunnerStub.resultsQueue = [
            .success(nil)
        ]

        Wendy.shared.addTask(tag: "tag", data: "dataId")

        let runTasksResults = await runAllTasks()

        XCTAssertEqual(runTasksResults.numberTasksRun, 1)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 1)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 0)

        // Expect task deleted, after success.
        let runTasks2ndTimeResults = await runAllTasks()
        XCTAssertEqual(runTasks2ndTimeResults.numberTasksRun, 0)
    }

    func test_runTasks_givenTaskFails_expectDoNotDelete() async {
        taskRunnerStub.resultsQueue = [
            .failure(ErrorForTesting.foo),
            .failure(ErrorForTesting.foo)
        ]

        Wendy.shared.addTask(tag: "tag", data: "dataId")

        let runTasksResults = await runAllTasks()

        XCTAssertEqual(runTasksResults.numberTasksRun, 1)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 0)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 1)

        // Expect task not deleted, after failure.
        let runTasks2ndTimeResults = await runAllTasks()
        XCTAssertEqual(runTasks2ndTimeResults.numberTasksRun, 1)
    }

    // MARK: Find tasks, using query

    struct Animal: Codable {
        let name: String
        let doesHaveLegs: Bool
        let doesHaveWings: Bool
        let doesHaveFur: Bool
    }

    let bird = Animal(name: "bird", doesHaveLegs: true, doesHaveWings: true, doesHaveFur: false)
    let bear = Animal(name: "bear", doesHaveLegs: true, doesHaveWings: true, doesHaveFur: true)

    func test_findTasksContainingAll_givenQuery_expectOnlyFindTasksContainingAllQueryTerms() async {
        Wendy.shared.addTask(tag: .random,
                             data: bird)
        let bearTaskId = Wendy.shared.addTask(tag: .random,
                                              data: bear)

        // Our query is specifically looking for animals with fur. The Animal *must* have fur.
        // We expect to only get bear, even though the bird does have legs.
        let actual = await Wendy.shared.findTasks(containingAll: ["doesHaveLegs": true, "doesHaveFur": true])

        XCTAssertEqual(actual, [bearTaskId])
    }

    func test_findTasksContainingAll_givenLongQuery_expectNoTasksReturned() async {
        Wendy.shared.addTask(tag: .random,
                             data: bird)
        Wendy.shared.addTask(tag: .random,
                             data: bear)

        // The bear matches the query, except there is a query term that the bear data type does not define.
        // Therefore, we expect to not match any animals.
        let actual = await Wendy.shared.findTasks(containingAll: ["doesHaveLegs": true, "doesHaveFur": true, "doesHaveHorns": true])

        XCTAssertEqual(actual, [])
    }

    func test_findTasksContainingAny_expectValueOfQueryTermToMatchTasks() async {
        Wendy.shared.addTask(tag: .random,
                             data: bird)
        Wendy.shared.addTask(tag: .random,
                             data: bear)

        // Test that the values in query are tested.
        let actual = await Wendy.shared.findTasks(containingAny: ["doesHaveLegs": false])

        XCTAssertEqual(actual, [])
    }

    func test_findTasksContainingAny_givenQuery_expectFindTasksContainingAnyQueryTerms() async {
        let birdTaskId = Wendy.shared.addTask(tag: .random,
                                              data: bird)
        let bearTaskId = Wendy.shared.addTask(tag: .random,
                                              data: bear)

        // Our query is not very specific. As long as you have legs or have fur, you will be matched. You do not need to have both.
        let actual = await Wendy.shared.findTasks(containingAny: ["doesHaveLegs": true, "doesHaveFur": true])

        XCTAssertEqual(actual, [birdTaskId, bearTaskId])
    }

    // MARK: listeners

    func test_runnerListener_expectAllCallbacksCalled() async {
        let listener = TaskRunnerListenerStub()
        WendyConfig.addTaskRunnerListener(listener)
        taskRunnerStub.resultsQueue = [
            .success(nil),
            .success(nil)
        ]

        XCTAssertEqual(listener.newTaskAddedCallCount, 0)
        Wendy.shared.addTask(tag: "tag", data: "dataId")
        Wendy.shared.addTask(tag: "tag", data: "dataId")
        XCTAssertEqual(listener.newTaskAddedCallCount, 2)

        XCTAssertEqual(listener.runningTaskCallCount, 0)
        XCTAssertEqual(listener.taskCompleteCallCount, 0)
        XCTAssertEqual(listener.taskSkippedCallCount, 0)
        XCTAssertEqual(listener.allTasksCompleteCallCount, 0)
        _ = await Wendy.shared.runTasks()
        XCTAssertEqual(listener.runningTaskCallCount, 2)
        XCTAssertEqual(listener.taskCompleteCallCount, 2)
        XCTAssertEqual(listener.taskSkippedCallCount, 0)
        XCTAssertEqual(listener.allTasksCompleteCallCount, 1)
    }

    func test_taskStatusListener_expectAllCallbacksCalled() async {
        let listener = PendingTaskStatusListenerStub()
        taskRunnerStub.resultsQueue = [
            .failure(ErrorForTesting.foo),
            .success(nil)
        ]

        let addedTaskId = Wendy.shared.addTask(tag: "tag", data: "dataId")
        WendyConfig.addTaskStatusListenerForTask(addedTaskId, listener: listener)

        XCTAssertNil(listener.runningTaskId)
        XCTAssertNil(listener.completeTaskId)
        XCTAssertNil(listener.skippedTaskId)

        _ = await Wendy.shared.runTasks()

        XCTAssertEqual(listener.runningTaskId, 1)
        XCTAssertEqual(listener.completeTaskId, 1)
        XCTAssertEqual(listener.completeSuccessful, false)

        _ = await Wendy.shared.runTasks()

        XCTAssertEqual(listener.runningTaskId, 1)
        XCTAssertEqual(listener.completeTaskId, 1)
        XCTAssertEqual(listener.completeSuccessful, true)
    }

    // MARK: groups

    func test_groups_givenTaskInGroupFails_expectRestOfGroupSkipped() async {
        taskRunnerStub.resultsQueue = [
            .failure(ErrorForTesting.foo)
        ]

        Wendy.shared.addTask(tag: "tag", data: "dataId", groupId: "groupName")
        Wendy.shared.addTask(tag: "tag", data: "dataId", groupId: "groupName")

        let runTasksResults = await runAllTasks()

        XCTAssertEqual(runTasksResults.numberTasksRun, 1)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 0)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 1)
    }

    func test_groups_givenTasksInGroupSucceed_expectAllTasksInGroupRun() async {
        taskRunnerStub.resultsQueue = [
            .success(nil),
            .success(nil)
        ]

        Wendy.shared.addTask(tag: "tag", data: "dataId", groupId: "groupName")
        Wendy.shared.addTask(tag: "tag", data: "dataId", groupId: "groupName")

        let runTasksResults = await runAllTasks()

        XCTAssertEqual(runTasksResults.numberTasksRun, 2)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 2)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 0)
        XCTAssertEqual(runTasksResults.numberSkippedTasks, 0)
    }

    // MARK: clear

    func test_clearTasks_givenTasksAdded_expectAllCancelAndDelete() async {
        Wendy.shared.addTask(tag: "tag", data: "dataId")
        Wendy.shared.addTask(tag: "tag", data: "dataId")

        await Wendy.shared.clear()

        let runTasksResults = await runAllTasks()
        XCTAssertEqual(runTasksResults.numberTasksRun, 0)
    }
}
