@testable import Wendy
import XCTest
@testable import Wendy_Example

class PendingTaskErrorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    func test_givenProperties_expectSameInstanceAsConstructor() {
        let expectedErrorId = "error-id"
        let expectedErrorMessage = "error"
        let expectedCreatedAt = Date()
        let actual = PendingTaskError.testing.get(pendingTask: AddGroceryListItemPendingTask(), errorId: expectedErrorId, errorMessage: expectedErrorMessage, createdAt: expectedCreatedAt)
        
        XCTAssertTrue(actual.pendingTask is AddGroceryListItemPendingTask)
        XCTAssertEqual(actual.errorMessage, expectedErrorMessage)
        XCTAssertEqual(actual.errorId, expectedErrorId)
        XCTAssertEqual(actual.createdAt, expectedCreatedAt)
    }
    
}
