import Foundation
import Wendy

enum AddGroceryListItemPendingTaskError: Error {
    case randomError
}

// optional below
extension AddGroceryListItemPendingTaskError: LocalizedError {
    var errorDescription: String? {
        return localizedDescription
    }

    var localizedDescription: String {
        switch self {
        case .randomError: return "Random error message here"
        }
    }
}

class AddGroceryListItemPendingTask: PendingTask {
    static let tag: Tag = String(describing: AddGroceryListItemPendingTask.self)

    var taskId: Double?
    var dataId: String?
    var groupId: String?
    var createdAt: Date?

    convenience init(groceryListItemName: String, groupId: String?) {
        self.init()
        self.dataId = groceryListItemName
        self.groupId = groupId
    }

    func isReadyToRun() -> Bool {
        let canRunTask = drand48() > 0.2
        return canRunTask
    }

    func runTask(complete: @escaping (Error?) -> Void) {
        sleep(2)

        let successful = drand48() > 0.5

        let result: Error? = successful ? nil : AddGroceryListItemPendingTaskError.randomError
        complete(result)
    }
}
