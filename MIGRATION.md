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

# v6 to v7 - Remove background fetch feature

The breaking change that caused Wendy to go from v6 to v7 is the removal of the iOS background fetch feature. Meaning, this line of code in your `AppDelegate` no longer exists: 

```swift
func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    let backgroundFetchResult = Wendy.shared.performBackgroundFetch()
    completionHandler(backgroundFetchResult.backgroundFetchResult)
}
```

This feature was removed because it does not add a lot of value to the project. 

If you want to periodically run Wendy in your app, it’s recommended to review up-to-date documentation for how to run background jobs on iOS and run Wendy in that job: `Wendy.shared. runTasks {...}`. 

# v7 to v8 - Replace `dataId` with `data: Codable` in task runner

The breaking change that caused Wendy to go from v7 to v8 is replacing the parameter `dataId: String?` with `data: Codable` in task runner subclasses. This change brings a lot of power to Wendy because you can now use objects instead of just Strings when you add tasks to Wendy. Less code for you to write later to perform your API calls! 

To migrate to v8, you will want to make sure that your tasks added with v7 of Wendy will continue to run. Here is some code to help you continue to use `dataId: String` for your existing tasks: 

```swift
import Wendy

class MyWendyTaskRunner: WendyTaskRunner {
    // 1. Change parameter 'dataId: String?' to 'data: Data?'
    func runTask(tag: String, data: Data?, complete: @escaping (Error?) -> Void) {
      switch tag {
        case "AddGroceryListItem":
          // 2. Convert the 'Data' data type back into 'String', as you were using before: 
          let dataId: String? = data?.wendyDecode()
          // 3. Done! Use 'dataId' as you were before! 
          ...
    }
}
```

Your task runner can use the new `Codable` feature, too. Use the `tag` to differentiate between tasks that were added in Wendy version \< 8 and tasks added in version \>= 8. See the README to learn how to use this new feature. 

# v8 to v9 - Removing callbacks in favor of Swift concurrency  alternatives
As I have continued to learn more about Swift Concurrency, I have continuously tried to improve the codebase for upcoming Swift 6 support with complete Swift concurrency checking enabled on the codebase. 

As part of these efforts, the codebase has moved away from callback functions to using `async/await` for all operations. This impacts your code in 2 ways: 

1. Your `WendyTaskRunner` is now using `async/await` instead of a callback function:
```swift
// Before: 
class MyWendyTaskRunner: WendyTaskRunner {
    func runTask(tag: String, data: Data?, complete: @escaping (Error?) -> Void) {
       // ... do work...when done, call callback: 
       complete()
    }
}

// Now: 
class MyWendyTaskRunner: WendyTaskRunner {
    func runTask(tag: String, data: Data?) async throws {
      // ...do work...when done, just return the function. 
    }
}
```

2. The public functions in `Wendy` that used a callback are now using `async/await`:
```swift
// Before: 
Wendy.shared.runTasks {}
Wendy.shared.runTask("") {}
Wendy.shared.clear()

// Now: 
await Wendy.shared.runTasks()
await Wendy.shared.runTask("")
await Wendy.shared.clear()
```

### Curious why this change was made?

After enabling Swift Concurrency complete checking on the project, I had to make some changes to the code such as making callback functions `Sendable`: 

```swift
Wendy.shared.runTasks {
  // This callback closure is Sendable. 
  // So, all code referenced in this block must also 
  // be Sendable...this could be annoying!  
}
```

I would rather not make random parts of the public API `Sendable` as that could cause a lot of annoyance to the developer using Wendy. I think a better approach would be to use  `async/await`  functions instead. Not only this, but reading and writing code with `async/await` is arguably better anyway.


[1]:	https://github.com/levibostian/Wendy-iOS/discussions/51
[2]:	BEST_PRACTICES.md#after-i-add-a-task-to-wendy-what-updates-should-i-make-to-my-apps-local-data-storage
[3]:	BEST_PRACTICES.md#handle-errors-when-a-task-runs
[4]:	README.md#getting-started
[5]:	https://github.com/levibostian/Wendy-iOS-Reader-CoreData