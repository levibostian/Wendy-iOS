import Foundation
@testable import Wendy
import XCTest

open class TestClass: XCTestCase {
    override open func setUp() {
        super.setUp()

        deleteKeyValueStore()
        deleteAllFileSystemFiles()

        resetDependencies()

        // Prevent scheduling any runs automatically. Makes tests flaky.
        WendyConfig.automaticallyRunTasks = false
    }

    public func resetDependencies() {
        DIGraph.shared.reset()
        Wendy.reset()
    }
}

extension TestClass {
    @discardableResult
    func runAllTasks() async -> PendingTasksRunnerResult {
        await Wendy.shared.runTasks()
    }
}
