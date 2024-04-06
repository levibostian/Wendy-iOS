//
//  WendyTaskRunner.swift
//  App
//
//  Created by Levi Bostian on 4/6/24.
//

import Foundation
import Wendy

public class MyWendyTaskRunner: WendyTaskRunnerConcurrency {
    public func runTask(tag: String, data: Data?) async throws {
        // Sleep for 2 seconds to simulate a network request
        try! await Task.sleep(nanoseconds: 500000000)
        
        // At this time, we are only testing that Wendy can successfully install and compile in an app.
        // This app is not meant to be a fully working example.
        // It's recommended to view the docs to learn how to create a proper Task Runner.
        
        // Just return, making all tasks successful.
        return
    }
}
