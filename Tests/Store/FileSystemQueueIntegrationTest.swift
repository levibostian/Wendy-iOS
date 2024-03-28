//
//  FileSystemQueueIntegrationTest.swift
//  Wendy_Tests
//
//  Created by Levi Bostian on 2/4/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
@testable import Wendy
import XCTest

class FileSystemQueueIntegrationTest: TestClass {
    private var reader: FileSystemQueueReader {
        DIGraph.shared.queueReader as! FileSystemQueueReader
    }
    private var writer: FileSystemQueueWriter {
        DIGraph.shared.queueWriter as! FileSystemQueueWriter
    }
    
    // MARK: simple reading and writing
    
    func test_givenNoTasks_expectReadEmptyList() {
        let actual = reader.getAllTasks()
        
        XCTAssertTrue(actual.isEmpty)
    }
    
    func test_getTaskById_givenNoTaskWithId_expectNil() {
        let _ = writer.add(tag: "foo", data: "", groupId: nil)
        XCTAssertNil(reader.getTaskByTaskId(2))
        XCTAssertNotNil(reader.getTaskByTaskId(1))
    }
    
    func test_givenDeleteTask_expectTaskGotDeleted() {
        let _ = writer.add(tag: "foo", data: "", groupId: nil)
        
        XCTAssertNotNil(reader.getTaskByTaskId(1))
        
        let _ = writer.delete(taskId: 1)
        
        XCTAssertNil(reader.getTaskByTaskId(1))
    }
    
    // MARK: persist tasks to data store
    
    func test_givenAddTasks_givenClearMemory_expectLoadPreviouslyAddedTasks() {
        let _ = writer.add(tag: "foo", data: "", groupId: nil)
        
        resetDependencies()
        
        let actual = reader.getAllTasks()
        XCTAssertEqual(actual[0].taskId, 1)
        XCTAssertEqual(actual[0].tag, "foo")
    }
}
