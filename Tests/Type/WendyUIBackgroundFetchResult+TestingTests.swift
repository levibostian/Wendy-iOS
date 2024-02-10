//
//  WendyUIBackgroundFetchResult+TestingTests.swift
//  Wendy_Tests
//
//  Created by Levi Bostian on 12/23/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import XCTest
@testable import Wendy

class WendyUIBackgroundFetchResult_TestingTests: XCTestCase {

    func test_get_givenRunnerResults_expectPopulatedLikeConstructor() {
        let givenTaskRunnerResult = PendingTasksRunnerResult.new(results: [
            TaskRunResult.cancelled
        ])
        
        let expected = WendyUIBackgroundFetchResult(taskRunnerResult: givenTaskRunnerResult, backgroundFetchResult: givenTaskRunnerResult.backgroundFetchResult)
        let actual = WendyUIBackgroundFetchResult.testing.get(runnerResult: givenTaskRunnerResult)
        
        XCTAssertEqual(actual.backgroundFetchResult, expected.backgroundFetchResult)
        XCTAssertEqual(actual.taskRunnerResult.runResults.count, givenTaskRunnerResult.runResults.count)
    }

}
