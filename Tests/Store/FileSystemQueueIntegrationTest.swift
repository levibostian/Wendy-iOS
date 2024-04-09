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
        _ = writer.add(tag: "foo", data: "", groupId: nil)
        XCTAssertNil(reader.getTaskByTaskId(2))
        XCTAssertNotNil(reader.getTaskByTaskId(1))
    }

    func test_givenDeleteTask_expectTaskGotDeleted() {
        _ = writer.add(tag: "foo", data: "", groupId: nil)

        XCTAssertNotNil(reader.getTaskByTaskId(1))

        _ = writer.delete(taskId: 1)

        XCTAssertNil(reader.getTaskByTaskId(1))
    }

    // MARK: persist tasks to data store

    func test_givenAddTasks_givenClearMemory_expectLoadPreviouslyAddedTasks() {
        _ = writer.add(tag: "foo", data: "", groupId: nil)

        resetDependencies()

        let actual = reader.getAllTasks()
        XCTAssertEqual(actual[0].taskId, 1)
        XCTAssertEqual(actual[0].tag, "foo")
    }
}
