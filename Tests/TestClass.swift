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
        
        resetDependencies()
        
        // Prevent scheduling any runs automatically. Makes tests flaky.
        Wendy.config.automaticallyRunTasks = false
    }
    
    public func resetDependencies() {
        DIGraph.shared.reset()
        Wendy.reset()
    }
    
}
