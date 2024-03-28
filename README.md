[![Version][image-1]][1]
[![License][image-2]][2]
[![Platform][image-3]][3]
![Swift 5.0.x][image-4]

# Wendy

Remove the difficulty in making offline-first iOS apps. Sync your offline device storage with remote cloud storage easily. When building offline-first mobile apps, there are *lots* of use cases to think about. Wendy takes care of handling them all for you!

![project logo. A picture of a person with long red hair.][image-5]

Android developer? [Check out the Android version of Wendy!][4]

## Announcements

If interested, see the [latest announcement][5] from maintainers discussing the latest set of changes coming to Wendy.

## What is Wendy?

Wendy is an iOS library designed to help you make your app offline-first. Use Wendy to define sync tasks, then Wendy will run those tasks periodically to keep your app's device offline data in sync with it's online remote storage.

Wendy is a FIFO task runner. You give it tasks one by one. Wendy persists those tasks to storage. Then, when Wendy has determined it's a good time for your task to run, it will call your task's sync function to perform a sync. Wendy goes through all of the tasks available one by one running them to succeed or fail and try again.

## Why use Wendy?

When creating offline-first mobile apps there are 2 tasks you need to do in your code. 1. Persisting data to the user's iOS device storage and 2. Sync that user's storage with remote online storage.

Wendy helps you with item #2. You define how the local storage is supposed to sync with the remote storage and Wendy takes care of running those tasks for you periodically when the time is right.

Wendy currently has the following functionality:

* Wendy is not opinionated in your network and data storage model. You may use whatever method you choose to sync data with it's remote storage and whatever method you choose to store data locally on the device. Wendy works with your workflow you already have. Store user data in Core Data locally and a Rails API for the cloud storage. Store user data in Realm locally and a Parse server for the cloud storage. Use just NSUserDefaults and GraphQL. Whatever you want, Wendy works with it.
* Dynamically allow and disallow tasks to sync at runtime. Wendy works in a FIFO style with it's tasks. When Wendy is about to run a certain task, it always asks the task if it is able to run.
* Group tasks together to enforce they all run (and succeed) in an exact order from start to finish.

# Install

Wendy-iOS is available through [CocoaPods][6]. To install it, simply add the following line to your Podfile:

```ruby
pod 'Wendy', '~> version-here'
```

(replace `version-here` with [![Version][image-6]][7])

# Getting started

For this getting started guide, lets work through an example for you to follow along with. Let's say you are building a grocery list app. We will call it, `Grocery List`.

### Initialize SDK

The first step to setting up Wendy is to initialize it when your app starts. 

Either in your  `AppDelegate` (UIKit apps) or in your `App` (SwiftUI), initialize the SDK: 

```swift
class AppDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {  
    Wendy.setup(taskRunner: MyWendyTaskRunner())
    ...
  }
}
```

```swift
class App {
  init() {
    Wendy.setup(taskRunner: MyWendyTaskRunner())
  }
}
```

To finish initialization, we need to create a task runner subclass. Create a new file in your project and use this placeholder code for now:  

```swift
import Wendy

class MyWendyTaskRunner: WendyTaskRunner {
    func runTask(tag: String, data: Data?, complete: @escaping (Error?) -> Void) {
    }
}

// Or, use the Swift Concurrency version: 
class MyWendyTaskRunner: WendyTaskRunnerConcurrency {
    func runTask(tag: String, data: Data?) async throws {
    }
}
```

Wendy is now configured. It's time to use it!

### Add tasks to sync data

Now that the SDK is initialized, it’s time to sync some data to our network API! 

In our Grocery List app example, we want to allow users to create new grocery items. Every time that a user creates a new grocery list item, we don't want to show them a progress bar saying, "Saving grocery list item..." while we perform an API call. We want to be able to *instantly* save that grocery list item and sync it with the cloud storage later so our user can get on with their life (can't you just see your App Store reviews going up, up, up right now? ⭐⭐⭐⭐⭐).

There are 2 steps to setting up Wendy for syncing data. 
1. [Adding tasks to Wendy][8]
2. [Writing the network code to perform the sync][9]

Let’s get into each of these steps. 

#### Adding tasks to Wendy  

To tell Wendy that you have a piece of data that needs to sync with a network API later, use `addTask`. Wendy will execute this task at a later time. 

```swift
let groceryListItem = GroceryListItem(price: ..., name: ...) 
Wendy.shared.addTask(tag: "AddGroceryListItem", data: groceryListItem) 

// Or, use an enum to avoid hard-coded strings: 
enum AsyncTasks: String {
  case addGroceryListItem
}

Wendy.shared.addTask(tag: AsyncTasks.addGroceryListItem, data: ...)
```

* `tag` is the data type identifier. It’s common to use 1 `tag`  per network API endpoint. Here, we use `AddGroceryListItem` because the user added a new grocery store list item. 
* `data` - is an object that will be used later when you sync with your network API. This object include all that your HTTP request needs to perform a request. In our example, the data is the grocery item that was added. 

#### Writing the network code to perform the sync

After you add a task to Wendy, Wendy will execute it at a later time. When it’s time for the task to run, Wendy will call your task runner that you provided when you initialized the SDK.  
  
Let’s look at some example code that runs the grocery store list item. 

```swift
import Wendy

class MyWendyTaskRunner: WendyTaskRunnerConcurrency {
    func runTask(tag: String, data: Data?) async throws {
      switch tag {
        case "AddGroceryListItem":
          // First, let's decode the 'data' parameter back into our object we added:
          let groceryListItem: GroceryListItem = data!.wendyDecode()!

         // Next, perform the HTTP call to sync your data with your network API. 
         // Note: The code below is for example, only. You will need to add your own HTTP code. 

		// If the API call throws, Wendy will retry running this task again in the future. Otherwise, Wendy will delete the task and not re-run it. 
         try await performApiCall(data)
    }
}

// If you prefer to use enums instead of hard-coded strings, you can do that, too:
func runTask(tag: String, data: Data?) async throws {
  switch AsyncTask(rawValue: tag) {
    case .addGroceryListItem:
  }
}
```

Done! You’re using Wendy 🎊! 

# Event listeners

Wendy tries to promote a positive user experience with offline-first mobile apps. One important step to this to communicating to your app user the status of their data. If a piece of data in the app has not yet synced successfully with the network API, your app should reflect this status in the UI. Using event listeners is one way to do that. 

When you call `Wendy.shared.addTask()`, that function returns an ID back to you. That ID maps to the 1 task that you added to Wendy. With this ID, you can check the status of a task in Wendy. 

```swift
// Add a listener to Wendy for the task that got added. 
// Note: Wendy keeps weak references to listeners. Keep a strong reference in your app. 
WendyConfig.addTaskStatusListenerForTask(taskId, listener: self) 

// Here is an example of making a UIKit View a listener of a Wendy 
// The UI changes depending on the state of the sync. 
extension View: PendingTaskStatusListener {

    func running(taskId: Double) {
        self.text = "Running"
    }

    func complete(taskId: Double, successful: Bool) {
        self.text = successful ? "Success!" : "Failure"
    }

    func skipped(taskId: Double, reason: ReasonPendingTaskSkipped) {
        self.text = "Skipped"
    }

}

```

It’s suggested to view the [Best practices doc][10] to learn more about making a great experience in your offline-first app. 

## Clear data

If you have the scenario ever happen where, for example, the user of your app logs out of your app. The scenario where you usually delete all of the data on the device for your app. You can clear all of Wendy's data:

```swift
Wendy.shared.clear()
```

*Note: If a `PendingTask` is currently being executed while you call `clear()`, that task will finish executing.*

# Testing

Wendy was built with unit/integration/UI testing in mind. Here is how to use Wendy in your tests:

## Write unit tests against `PendingTask` implementations

Your implementations of `PendingTask` should be no problem to test. `PendingTask` is just a protocol. You can unit test your implementation using dependency injection, for example, to test all of the functions of `PendingTask`.

## Write unit tests for code that depends on Wendy classes

When writing tests against code Wendy classes such as `PendingTasksRunnerResult`, Wendy allows you to create instances of these internal classes with the convenient `.testing.` property added to these internal classes. 

Here are some examples:

```swift
PendingTasksRunnerResult.testing.result(from results: [TaskRunResult])
```

## Write integration tests around Wendy

Coming soon! 

You may be able to do this already, but it has not been tested. A good place to start would be clear Wendy before each test and use it like normal. See where that takes you. Report issues as you encounter them. 

## Example

To run the example project, clone the repo, and run `pod install` from the `Example/` directory first. Then, open XCode and run the project.

## Documentation

Wendy currently *does not* have full code documentation. It is planned to have full documentation generated via jazzy in the near future.

Until then, the best thing to do is:

* Read this README on how to get started.
* Wendy-Android has [full documentation created for it][11]. If you are wondering how a specific function works, you may be able to learn there. *Warning: Wendy-Android and Wendy-iOS are kept up to date between one another as soon as possible. When a bug is fixed on one, the other gets the same bug fixed on it as well. However, it may take a day or two for this sync to happen by the contributors. With that in mind, the documentation might be a tad bit off between the libraries.*

## Configure Wendy

Use the class `WendyConfig` to configure the behavior of Wendy.

* Register listeners to Wendy task runner.

```swift
WendyConfig.addTaskRunnerListener(listener: listener)
```

* Register listeners to a specific Wendy `PendingTask`.

```swift
WendyConfig.addTaskStatusListenerForTask(taskId: pendingTaskId, listener: listener)
```

* Have Wendy log debug statements as it's running during development.

```swift
WendyConfig.debug = true # default is false.
```

I recommend doing the following:

```swift
#if DEBUG
WendyConfig.debug = true
#endif
```

## Maintainers

* Levi Bostian - [GitHub][12]

![Levi Bostian image][image-7]

## License

Wendy-iOS is available under the MIT license. See the LICENSE file for more info.

## Contribute

Wendy is open for pull requests. 

**Want to add features to Wendy?** Before you decide to take a bunch of time and add functionality to the library, please, [create an issue][13] stating what you wish to add. This might save you some time in case your purpose does not fit well in the use cases of Wendy.

Follow the steps below to compile the Wendy project on your machine for contributing!

* Install these development tools:

[mint][14] used to run other development CLI commands such as linter/formatter. 
[taskfile][15] an alternative to `Makefile` to run commands. 

* Generate the boilerplate code, otherwise you will not be able to compile the code.

`task codegen`

* Open up the `Package.swift` file in XCode. Once you are in Xcode, you can now compile the SDK or run tests.

# Credits

Header photo by [Allef Vinicius][16] on [Unsplash][17]

[1]:	http://cocoapods.org/pods/Wendy
[2]:	http://cocoapods.org/pods/Wendy
[3]:	http://cocoapods.org/pods/Wendy
[4]:	https://github.com/levibostian/wendy-android
[5]:	https://github.com/levibostian/Wendy-iOS/discussions/categories/announcements
[6]:	http://cocoapods.org
[7]:	http://cocoapods.org/pods/Wendy
[8]:	#adding-tasks-to-wendy
[9]:	#writing-the-network-code-to-perform-the-sync
[10]:	BEST_PRACTICES.md
[11]:	https://levibostian.github.io/Wendy-Android/wendy/
[12]:	https://github.com/levibostian
[13]:	https://github.com/levibostian/Wendy-iOS/issues/new
[14]:	https://github.com/yonaskolb/Mint?tab=readme-ov-file#installing
[15]:	https://taskfile.dev/installation/
[16]:	https://unsplash.com/photos/FPDGV38N2mo?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText
[17]:	https://unsplash.com/search/photos/red-head?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText

[image-1]:	https://img.shields.io/cocoapods/v/Wendy.svg?style=flat
[image-2]:	https://img.shields.io/cocoapods/l/Wendy.svg?style=flat
[image-3]:	https://img.shields.io/cocoapods/p/Wendy.svg?style=flat
[image-4]:	https://img.shields.io/badge/Swift-5.0.x-orange.svg
[image-5]:	misc/wendy_logo.jpg
[image-6]:	https://img.shields.io/cocoapods/v/Wendy.svg?style=flat
[image-7]:	https://gravatar.com/avatar/22355580305146b21508c74ff6b44bc5?s=250