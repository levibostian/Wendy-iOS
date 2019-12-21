import Foundation

// this file exists for an easy copy/paste to the README for docs on how to create a PendingTask.

/**
 import Wendy

 class CreateGroceryListItemPendingTask: PendingTask {

 static let pendingTaskRunnerTag = String(describing: CreateGroceryListItemPendingTask.self)
 static let groceryStoreItemTextTooLongErrorId = "GROCERY_STORE_ITEM_TEXT_TOO_LONG"

 var taskId: Double?
 var dataId: String?
 var groupId: String?
 var tag: String = CreateGroceryListItemPendingTask.pendingTaskRunnerTag
 var manuallyRun: Bool = false
 var createdAt: Date?

 convenience init(groceryStoreItemId: Int) {
     self.init()
     self.dataId = String(groceryStoreItemId)
 }

 func isReadyToRun() -> Bool {
     return true
 }

 func runTask(complete: @escaping (Bool) -> Void) {
     // Here, instantiate your dependencies, talk to your DB, your API, etc. Run the task.
     // After the task succeeds or fails, return to Wendy the result.

     let groceryStoreItem = localDatabase.queryGroceryStoreItem(self.dataId)

     performApiCall(groceryStoreItem, complete: { apiCallResult in
         if let apiError = apiCallResult.error {
             // There was an error. Parse the error and decide what to do from here.

             // If it's an error that deserves the attention of your user to fix, make sure and record it with Wendy.
             // If the error is a network error, for example, that does not require the user's attention to fix, do *not* record an error to Wendy.
             // Wendy will not run your task if there is a recorded error for it. Record an error, prompt your user to fix it, then resolve it ASAP so it can run.
             Wendy.shared.recordError(taskId: self.taskId, humanReadableErrorMessage: "Grocery store item too long. Please shorten it up for me.", errorId: groceryStoreItemTextTooLongErrorId)

             complete(false)
         } else {
             complete(true)
         }
     })
 }

 }
 */
