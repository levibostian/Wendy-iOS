//
//  PendingTasksManagerTests.swift
//  Wendy_Tests
//
//  Created by Levi Bostian on 2/9/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import Wendy

class PendingTasksManagerTest: TestClass {
    
    private var queueReader: QueueReaderStub!
    private var queueReader2: QueueReaderStub!
        
    private var pendingTasksManager: PendingTasksManager {
        DIGraph.shared.pendingTasksManager
    }
        
        override func setUp() {
            super.setUp()

            queueReader = QueueReaderStub()
            queueReader2 = QueueReaderStub()
            
            pendingTasksManager.queueReaders = [queueReader, queueReader2]
        }
    
    // MARK: getAllTasks
    
    func test_getAllTasks_givenNoTasks_expectEmptyList() {
        queueReader.allTasks = []
        queueReader2.allTasks = []
        
        let actual = pendingTasksManager.getAllTasks()
        
        XCTAssertTrue(actual.isEmpty)
    }
    
    func test_getAllTasks_expectTasksSorted() {
        let givenOldestTask = PendingTask(tag: "foo", taskId: 1, dataId: nil, groupId: nil, createdAt: Date())
        let givenMiddleTask = PendingTask(tag: "bar", taskId: 2, dataId: nil, groupId: nil, createdAt: Date().addingTimeInterval(1))
        let givenNewestTask = PendingTask(tag: "baz", taskId: 3, dataId: nil, groupId: nil, createdAt: Date().addingTimeInterval(2))
        
        queueReader.allTasks = [givenMiddleTask]
        queueReader2.allTasks = [givenNewestTask, givenOldestTask]
        
        let actual = pendingTasksManager.getAllTasks()
        
        XCTAssertEqual(actual[0].taskId, 1)
        XCTAssertEqual(actual[1].taskId, 2)
        XCTAssertEqual(actual[2].taskId, 3)
    }
    
    // MARK: getTaskByTaskId
    
    func test_getTaskByTaskId_givenTaskExists_expectTask() {
        let givenTask = PendingTask(tag: "foo", taskId: 1, dataId: nil, groupId: nil, createdAt: Date())
        let givenTaskWithDifferentId = PendingTask(tag: "foo", taskId: 2, dataId: nil, groupId: nil, createdAt: Date())
        
        queueReader.allTasks = [givenTask]
        queueReader2.allTasks = [givenTaskWithDifferentId]
        
        let actual = pendingTasksManager.getTaskByTaskId(1)
        
        XCTAssertEqual(actual?.taskId, givenTask.taskId)
    }
    
    func test_getTaskByTaskId_givenTaskDoesNotExist_expectNil() {
        queueReader.allTasks = [PendingTask(tag: "foo", taskId: 2, dataId: nil, groupId: nil, createdAt: Date())]
        queueReader2.allTasks = [PendingTask(tag: "foo", taskId: 3, dataId: nil, groupId: nil, createdAt: Date())]
        
        let actual = pendingTasksManager.getTaskByTaskId(1)
        
        XCTAssertNil(actual)
    }
    
    // MARK: getNextTaskToRun
    
    func test_getNextTaskToRun_givenNoTasks_expectNil() {
        queueReader.allTasks = []
        queueReader2.allTasks = []
        
        let actual = pendingTasksManager.getNextTaskToRun(1, filter: nil)
        
        XCTAssertNil(actual)
    }
    
    func test_getNextTaskToRun_givenTaskInMultipleReaders_expectGetTask() {
        let givenTask = PendingTask(tag: "foo", taskId: 1, dataId: nil, groupId: nil, createdAt: Date())
        
        queueReader.allTasks = []
        queueReader2.allTasks = [givenTask]
        
        let actual = pendingTasksManager.getNextTaskToRun(1, filter: nil)
        
        XCTAssertEqual(actual?.tag, "foo")
    }
    
}
