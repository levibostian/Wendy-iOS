//
//  File.swift
//  
//
//  Created by Levi Bostian on 2/13/24.
//

import Foundation
import XCTest
@testable import Wendy

open class TestClass: XCTestCase {
    
    open override func setUp() {
        super.setUp()
        
        deleteKeyValueStore()
        deleteAllFileSystemFiles()
        
        // Reset singletons
        FileSystemQueueImpl.reset()
        FileSystemQueueWriter.reset()
        PendingTasksRunner.reset()
        Wendy.reset()
        PendingTasksManager.reset()
        
        // Prevent scheduling any runs automatically. Makes tests flaky.
        WendyConfig.automaticallyRunTasks = false
    }
    
}
