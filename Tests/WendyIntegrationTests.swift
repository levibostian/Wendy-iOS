//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/11/24.
//

import Foundation
import XCTest
@testable import Wendy

class WendyIntegrationTests: TestClass {
    
    private var taskRunnerStub: TaskRunnerStub!
    
    private var wendy: Wendy {
        Wendy.shared
    }
    
    override func setUp() {
        super.setUp()
        
        taskRunnerStub = TaskRunnerStub()
        
        Wendy.setup(taskRunner: taskRunnerStub)
    }
    
    // MARK: adding tasks
    
    func test_addTasks_givenAddTasksWithSameArguments_expectEveryTaskUnique() {
        let task1 = wendy.addTask(tag: "tag", dataId: "dataId")
        let task2 = wendy.addTask(tag: "tag", dataId: "dataId")
        
        XCTAssertNotEqual(task1, task2)
        
        let taskGroup1 = wendy.addTask(tag: "tag", dataId: "dataId", groupId: "groupName")
        let taskGroup2 = wendy.addTask(tag: "tag", dataId: "dataId", groupId: "groupName")
        
        XCTAssertNotEqual(taskGroup1, taskGroup2)
    }
    
    // MARK: run tasks
    
    func test_runTasks_givenNoTasksAdded_expectRunNoTasks() {
        XCTAssertEqual(runAllTasks().numberTasksRun, 0)
    }
    
    func test_runTasks_givenTaskSuccedds_expectDeleteTask() {
        taskRunnerStub.resultsQueue = [
            .success(nil)
        ]
        
        let _ = wendy.addTask(tag: "tag", dataId: "dataId")
        
        let runTasksResults = runAllTasks()
        
        XCTAssertEqual(runTasksResults.numberTasksRun, 1)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 1)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 0)
        
        // Expect task deleted, after success.
        let runTasks2ndTimeResults = runAllTasks()
        XCTAssertEqual(runTasks2ndTimeResults.numberTasksRun, 0)
    }
    
    func test_runTasks_givenTaskFails_expectDoNotDelete() {
        taskRunnerStub.resultsQueue = [
            .failure(ErrorForTesting.foo),
            .failure(ErrorForTesting.foo)
        ]
        
        let _ = wendy.addTask(tag: "tag", dataId: "dataId")
        
        let runTasksResults = runAllTasks()
        
        XCTAssertEqual(runTasksResults.numberTasksRun, 1)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 0)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 1)
        
        // Expect task not deleted, after failure.
        let runTasks2ndTimeResults = runAllTasks()
        XCTAssertEqual(runTasks2ndTimeResults.numberTasksRun, 1)
    }
    
    // MARK: listeners 
    
    func test_runnerListener_expectAllCallbacksCalled() {
        let listener = TaskRunnerListenerStub()
        WendyConfig.addTaskRunnerListener(listener)
        taskRunnerStub.resultsQueue = [
            .success(nil),
            .success(nil)
        ]

        XCTAssertEqual(listener.newTaskAddedCallCount, 0)
        let _ = wendy.addTask(tag: "tag", dataId: "dataId")
        let _ = wendy.addTask(tag: "tag", dataId: "dataId")
        XCTAssertEqual(listener.newTaskAddedCallCount, 2)
        
        XCTAssertEqual(listener.runningTaskCallCount, 0)
        XCTAssertEqual(listener.taskCompleteCallCount, 0)
        XCTAssertEqual(listener.taskSkippedCallCount, 0)
        XCTAssertEqual(listener.allTasksCompleteCallCount, 0)
        let _ = runAllTasks()
        XCTAssertEqual(listener.runningTaskCallCount, 2)
        XCTAssertEqual(listener.taskCompleteCallCount, 2)
        XCTAssertEqual(listener.taskSkippedCallCount, 0)
        XCTAssertEqual(listener.allTasksCompleteCallCount, 1)
    }
    
    func test_taskStatusListener_expectAllCallbacksCalled() {
        let listener = PendingTaskStatusListenerStub()
        taskRunnerStub.resultsQueue = [
            .failure(ErrorForTesting.foo),
            .success(nil)
        ]
        
        let addedTaskId = wendy.addTask(tag: "tag", dataId: "dataId")
        WendyConfig.addTaskStatusListenerForTask(addedTaskId, listener: listener)
        
        XCTAssertNil(listener.runningTaskId)
        XCTAssertNil(listener.completeTaskId)
        XCTAssertNil(listener.skippedTaskId)
        
        let _ = runAllTasks()
        
        XCTAssertEqual(listener.runningTaskId, 1)
        XCTAssertEqual(listener.completeTaskId, 1)
        XCTAssertEqual(listener.completeSuccessful, false)
        
        let _ = runAllTasks()
        
        XCTAssertEqual(listener.runningTaskId, 1)
        XCTAssertEqual(listener.completeTaskId, 1)
        XCTAssertEqual(listener.completeSuccessful, true)
    }
    
    // MARK: groups
    
    func test_groups_givenTaskInGroupFails_expectRestOfGroupSkipped() {
        taskRunnerStub.resultsQueue = [
            .failure(ErrorForTesting.foo)
        ]
        
        let _ = wendy.addTask(tag: "tag", dataId: "dataId", groupId: "groupName")
        let _ = wendy.addTask(tag: "tag", dataId: "dataId", groupId: "groupName")
        
        let runTasksResults = runAllTasks()
        
        XCTAssertEqual(runTasksResults.numberTasksRun, 1)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 0)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 1)
    }
    
    func test_groups_givenTasksInGroupSucceed_expectAllTasksInGroupRun() {
        taskRunnerStub.resultsQueue = [
            .success(nil),
            .success(nil)
        ]
        
        let _ = wendy.addTask(tag: "tag", dataId: "dataId", groupId: "groupName")
        let _ = wendy.addTask(tag: "tag", dataId: "dataId", groupId: "groupName")
        
        let runTasksResults = runAllTasks()
        
        XCTAssertEqual(runTasksResults.numberTasksRun, 2)
        XCTAssertEqual(runTasksResults.numberSuccessfulTasks, 2)
        XCTAssertEqual(runTasksResults.numberFailedTasks, 0)
        XCTAssertEqual(runTasksResults.numberSkippedTasks, 0)
    }
    
    // MARK: threading
    
    func test_threading_givenAddTasksInDifferentThreads_expectAllGetAddedAndRun() {
        let expectToAddTasks = expectation(description: "expect to add tasks")
        expectToAddTasks.expectedFulfillmentCount = 2

        DispatchQueue(label: "a thread").async {
            let _ = self.wendy.addTask(tag: "tag", dataId: "dataId")
            expectToAddTasks.fulfill()
        }
        
        DispatchQueue(label: "another thread").async {
            let _ = self.wendy.addTask(tag: "tag", dataId: "dataId")
            expectToAddTasks.fulfill()
        }
        
        wait(for: [expectToAddTasks], timeout: 1.0)
        
        taskRunnerStub.resultsQueue = [
            .success(nil),
            .success(nil)
        ]
        
        let runTasksResults = self.runAllTasks()
        XCTAssertEqual(runTasksResults.numberTasksRun, 2)
    }
    
    // Wendy has the ability to run a single task whenever you want. So if wendy is running 100 tasks, for example, you can run a single task and not have to wait for wendy to finish running the rest of the 100 tasks.
    func test_runTask_givenAlreadyRunningAllTasks_expectBeAbleToRunSingleTaskInMiddleOfRunningAll() {
        _ = Wendy.shared.addTask(tag: "task1", dataId: "dataId")
        _ = Wendy.shared.addTask(tag: "task2", dataId: "dataId")
        _ = Wendy.shared.addTask(tag: "task3", dataId: "dataId")
        
        let expectToRunTask1 = expectation(description: "expect to run task 1")
        let expectToRunTask2 = expectation(description: "expect to run task 2")
        let expectToRunTask3 = expectation(description: "expect to run task 3")
        let expectToFinishRuningAllTasks = expectation(description: "expect to finish running all tasks")
        let expectToFinishRunningSingleTask = expectation(description: "expect to finish running single task")
        
        taskRunnerStub.runTaskClosure = { tagOfTaskWeAreRunning, _ in
            
            // When we begin running all tasks, ask Wendy to run task 3, which means it would run it before task 2.
            if tagOfTaskWeAreRunning == "task1" {
                Wendy.shared.runTask(3) { _ in
                    expectToFinishRunningSingleTask.fulfill()
                }
            }
            
            if tagOfTaskWeAreRunning == "task1" {
                expectToRunTask1.fulfill()
            } else if tagOfTaskWeAreRunning == "task2" {
                expectToRunTask2.fulfill()
            } else if tagOfTaskWeAreRunning == "task3" {
                expectToRunTask3.fulfill()
            }
        }
        
        Wendy.shared.runTasks { _ in
            expectToFinishRuningAllTasks.fulfill()
        }
    
        wait(for: [
            expectToRunTask1,
            expectToRunTask3,
            expectToFinishRunningSingleTask,
            expectToRunTask2,
            expectToFinishRuningAllTasks
        ], timeout: 1.0, enforceOrder: true)
    }

    func test_runAllTasks_givenAlreadyRunning_expectIgnoreRequest() {
        let expectToFinishRunningAllTasks = expectation(description: "expect to finish running all tasks")
        let expectToIgnoreRequestToRunAllTasks = expectation(description: "expect to ignore request to run all tasks")
        
        _ = Wendy.shared.addTask(tag: "task1", dataId: "dataId")
        _ = Wendy.shared.addTask(tag: "task2", dataId: "dataId")
        
        taskRunnerStub.runTaskClosure = { tagOfTaskWeAreRunning, _ in
            // When we begin running all tasks, ask Wendy to run all tasks again. The request should be ignored so it should complete fast.
            if tagOfTaskWeAreRunning == "task1" {
                Wendy.shared.runTasks { _ in
                    expectToIgnoreRequestToRunAllTasks.fulfill()
                }
            }
        }
        
        Wendy.shared.runTasks { _ in
            expectToFinishRunningAllTasks.fulfill()
        }
    
        wait(for: [
            expectToIgnoreRequestToRunAllTasks,
            expectToFinishRunningAllTasks,
        ], timeout: 1.0, enforceOrder: true)
    }
    
    // MARK: clear
    
    func test_clearTasks_givenTasksAdded_expectAllCancelAndDelete() {
        let _ = wendy.addTask(tag: "tag", dataId: "dataId")
        let _ = wendy.addTask(tag: "tag", dataId: "dataId")
        
        wendy.clear()
        
        sleep(1) // give wendy time to run all scheduled tasks that do the deleting.
        let runTasksResults = runAllTasks()
        XCTAssertEqual(runTasksResults.numberTasksRun, 0)
    }
}

extension WendyIntegrationTests {
    @discardableResult
    func runAllTasks() -> PendingTasksRunnerResult {
        let expectToRunAllTasks = expectation(description: "expect to run all tasks")
        
        var runResult: PendingTasksRunnerResult!
        wendy.runTasks { result in
            runResult = result
            expectToRunAllTasks.fulfill()
        }
        
        wait(for: [expectToRunAllTasks], timeout: 1.0)
        
        return runResult
    }
}
