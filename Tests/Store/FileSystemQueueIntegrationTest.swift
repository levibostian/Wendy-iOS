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

class FileSystemQueueIntegrationTest: XCTestCase {
    private var reader: FileSystemQueueReader!
    private var writer: FileSystemQueueWriter!
    
    override func setUp() {
        super.setUp()
        
        FileSystemQueueImpl.reset()
        deleteAllFileSystemFiles()
        deleteKeyValueStore() 

        reader = FileSystemQueueReader()
        writer = FileSystemQueueWriter()
    }
    
    // MARK: simple reading and writing
    
    func test_givenNoTasks_expectReadEmptyList() {
        let actual = reader.getAllTasks()
        
        XCTAssertTrue(actual.isEmpty)
    }
    
    func test_getTaskById_givenNoTaskWithId_expectNil() {
        let _ = writer.add(tag: "foo", dataId: nil, groupId: nil)
        XCTAssertNil(reader.getTaskByTaskId(2))
        XCTAssertNotNil(reader.getTaskByTaskId(1))
    }
    
    func test_givenDeleteTask_expectTaskGotDeleted() {
        let _ = writer.add(tag: "foo", dataId: nil, groupId: nil)
        
        XCTAssertNotNil(reader.getTaskByTaskId(1))
        
        let _ = writer.delete(taskId: 1)
        
        XCTAssertNil(reader.getTaskByTaskId(1))
    }
}
