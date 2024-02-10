# Migration docs

## v1 to v2 - Removal of manually running tasks

The breaking change that caused Wendy to go from v1 to v2 is the removal of a feature known as *manually run tasks*. The idea behind this feature was to make Wendy a generic job scheduler for your app that could either run all of your tasks for you and you could manage some yourself. 

[The maintainers of Wendy decided to bring focus back to Wendy][1] and make it really good at one thing. In order to bring this focus, this feature of manually running a task does not add value to the project. 

If your app currently uses this feature, the recommended migration path is to no longer use Wendy to run the jobs in your app you're manually managing. Wendy does not provide an alternative feature inside of it that can be used as an alternative. Either write code yourself to run these tasks or use a 3rd party SDK to run these jobs. 

# v2 to v3 - Removal of Collections feature

The breaking change that caused Wendy to go from v2 to v3 is the removal of a feature known as *Collections*. This feature was originally added to satisfy an old best practice that was recommended at the time. However, this best practice is no longer recommended. Because of that, Collections has been removed to encourage the new best practice instead.  

If your app currently uses this feature, the recommended migration path is to modify your app’s logic to [follow this new best practice][2]. 

# v3 to v4 - Removal of error reporting feature

The breaking change that caused Wendy to go from v3 to v4 is the removal of a feature known as *error reporting*. This feature was originally added to satisfy an old best practice that was recommended at the time. However, this best practice is no longer recommended. Because of that, error reporting has been removed to encourage the new best practice instead.  

If your app currently uses this feature, the recommended migration path is to modify your app’s logic to [follow this new best practice][3]. 

# v4 to v5 - No more `PendingTask` subclasses

The breaking change that caused Wendy to go from v4 to v5 is the removal of the `PendingTask` protocol. This change drastically reduces the amount of boilerplate code required to use Wendy! 🎊 Let’s go over how you can migrate your code to this breaking change and get your apps compiling again. 

Let’s use an example. Let’s say that your app currently has this `PendingTask` in it. 

```swift
import Wendy

class CreateGroceryListItemPendingTask: PendingTask {

    static let tag: Tag = String(describing: CreateGroceryListItemPendingTask.self)

    var taskId: Double?
    var dataId: String?
    var groupId: String?
    var createdAt: Date?

    convenience init(groceryStoreItemId: Int) {
        self.init()
        self.dataId = String(groceryStoreItemId)
    }

    func isReadyToRun() -> Bool {
        return true
    }

    func runTask(complete: @escaping (Error?) -> Void) {
        // Here, instantiate your dependencies, talk to your DB, your API, etc. Run the task.
        // After the task succeeds or fails, return to Wendy the result.

        let groceryStoreItem = localDatabase.queryGroceryStoreItem(self.dataId)

        performApiCall(groceryStoreItem, complete: { apiCallResult in
            complete(apiCallResult.error)            
        })
    }

}
```

Here are the steps that we need to take to migrate away from using this: 
1. All of the class parameters will now go into your `Wendy.shared.addTask()` call.

```swift
// Before
Wendy.shared.addTask(CreateGroceryListItemPendingTask(groceryStoreItemId: 5))

// After
Wendy.shared.addTask(tag: "CreateGroceryListItemPendingTask", dataId: String(groceryStoreItemId))
```

2. All of the code inside of `runTask` will be moved into a new task runner. See the updated [getting started docs][4] to learn how to create a new task runner in your app.

```swift
import Wendy

class MyWendyTaskRunner: WendyTaskRunner {
    func runTask(tag: String, dataId: String?, complete: @escaping (Error?) -> Void) {        
        switch tag {
        case "CreateGroceryListItemPendingTask":
			// Here, instantiate your dependencies, talk to your DB, your API, etc. Run the task.
			// After the task succeeds or fails, return to Wendy the result.
			
			let groceryStoreItem = localDatabase.queryGroceryStoreItem(self.dataId)
			
			performApiCall(groceryStoreItem, complete: { apiCallResult in
			  complete(apiCallResult.error)            
			})
           break 
        }
    }
}
```

3. Delete your `PendingTaskFactory` class. It’s no longer needed!

# v5 to v6 - Change data store from CoreData to File System

The breaking change that caused Wendy to go from v5 to v6 is that we have changed how SDK data is stored on the device. 

For those of you who have installed any version of Wendy \<= 5, all tasks that your app added to Wendy were saved on the device via the CoreData framework. Starting in Wendy version 6, all tasks that your app adds to Wendy will be instead saved to files in the file system on the device.  **All CoreData framework related code has been removed from the Wendy codebase.** This means that all Wendy tasks saved via CoreData will not be run by Wendy, *unless you add the new plugin* when you upgrade Wendy to version 6. 

Navigate over to [the README for a new, separate CocoaPod][5] to learn how to install this plugin in your app. 

When you install this plugin, all tasks added to Wendy in version 6 will still be written to the file system. This plugin will simply read tasks added when version \<= 5 was running in the app. 

[1]:	https://github.com/levibostian/Wendy-iOS/discussions/51
[2]:	BEST_PRACTICES.md#after-i-add-a-task-to-wendy-what-updates-should-i-make-to-my-apps-local-data-storage
[3]:	BEST_PRACTICES.md#handle-errors-when-a-task-runs
[4]:	README.md#getting-started
[5]:	https://github.com/levibostian/Wendy-iOS-Reader-CoreData