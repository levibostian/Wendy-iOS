import Foundation
@testable import Wendy
import XCTest

open class TestClass: XCTestCase {
    override open func setUp() {
        super.setUp()

        performCommonSetup()
    }
}

extension XCTestCase {
    func performCommonSetup() {
        deleteKeyValueStore()
        deleteAllFileSystemFiles()

        resetDependencies()

        // Prevent scheduling any runs automatically. Makes tests flaky.
        WendyConfig.automaticallyRunTasks = false
    }

    func resetDependencies() {
        // reset all dependencies
        DIGraph.shared.reset()
    }

    @discardableResult
    func runAllTasks() async -> PendingTasksRunnerResult {
        await Wendy.shared.runTasks()
    }
}
