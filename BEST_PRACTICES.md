# Best practices

Learning Wendy's public API is only part of the puzzle. Learning how to use Wendy to build an offline-first app is just as important. Use this document as a guide to help you design offline-first app. 

# After I add a task to Wendy, what updates should I make to my app's local data storage?

If your app uses the Wendy SDK as well as a local app data storage, such as a database, to cache some data offering offline support, this section is for you. 

Let's use an example to explain this situation. You're building a social networking app where you can send and receive friend requests. 

1. Your app shows a list of friend requests inside of your app. 
2. Your app user decides to accept one of these friend requests within the friend requests list. They click the button to "Accept". 
3. Your app adds a new task to Wendy to accept this friend request. Wendy will sync this change with the network API as soon as it can. 
4. Now what? Should we update the local database in the app saying that the friend request was successful? What should we do in our UI? 

Using this example above, here is the recommended approach to take in your app.

After the user clicks the button to accept a friend request...

1. Add a new task to Wendy that will send a request to the network API accepting this friend request. 
2. Modify your app's local data to indicate that this friend request is in a pending state. Modify your app's local device database or some other data store to indicate that this friend request was accepted on the device, but the network API is not yet aware so the friend request is not yet in a succeeded state. 
3. In the Wendy task that performs the friend request operation with your network API, have this Wendy task send a request to the network API to accept the friend request. On success, modify your app's local data to indicate that the friend request has succeeded! 


# Handle errors when a task runs
What do you do when a Wendy task has an error? 

```swift
func runTask(complete: @escaping (Error?) -> Void) {
   performHttpRequest(groceryStoreItem, complete: { apiCallResult in
     if let error = apiCallResult {
       // ???????????
     }
}
```

This situation is mostly up to you to decide based on the type of data that is syncing and the UI of your app. Here are some suggestions to try and give you some ideas on how to handle these situations. 

* **The HTTP request failed because of a bug in the code**, it would be a good idea to log this error to your app’s error reporting tool. 
* **The HTTP request failed because of no network connection**, you could simply tell Wendy to try running the task again later. 
* **The HTTP request failed because of app user error** (they have an invalid character in their new username they chose for their profile), you could log this error in your app and bring attention to this error in the UI of the app so the user can fix it and retry. 

When Wendy executes your task, the result you return back to Wendy determines if Wendy should retry the task or not. Here is some code to demonstrate how to communicate with Wendy how to handle a task when an error happens. 

```swift
class CreateGroceryListItemPendingTask: PendingTask {

    func runTask(complete: @escaping (Error?) -> Void) {
        performHttpRequest(groceryStoreItem, complete: { apiCallResult in

      if noNetworkConnection {
        // By returning an error to Wendy, we are telling Wendy to retry running the task again later. 
        complete(NoNetworkConnectionError())
      }

      if httpRequestFailedBecauseBugInCode {
        errorReportingTool(...) // Could be a good idea to log this as an error to notify your team to fix this bug. 

        // Tell wendy the task succeeded so Wendy does not retry running it. 
        // We don't want Wendy to retry the task because it will never succeed if there is a bug in the code. 
        complete() 
      }
      
      if userOfAppMadeMistake {
        // Tell wendy the task succeeded so Wendy does not retry running it. 
        // The task will never succeed if the HTTP request will always fail. 
        complete()
    }
}
```
> Note: This code is meant to explain a concept, not give you example code to put into your app. This code is not meant to copy/paste. 

### User experience when an error happens 

When you’re building an offline-first app, the user experience of your app is more unique because of new use cases to handle. Such as when an error happens during the sync operation. 

Let’s use an example to talk about user experience. If you’re building a social media app that allows users to submit status updates. A user of your app is offline, they type in a status in the app, and the task gets added to Wendy to sync in the future. 

5 minutes later when the network connection is established, Wendy tries to run the task to send this status update to the network API. The HTTP request fails because the user of your app used emojis and your network API doesn’t allow emojis (how lame! 🤣). 

When the user of your app submitted a status update, they assumed that the status is going to be visible to all of their friends at some point. If the Wendy task fails, you should bring this error to the attention of your user. Notify the user in the app that this particular status was not a valid one, the status is not visible to friends, and that they must try sending a new valid status again. If Wendy tasks fail and your app users are not informed of these errors, your users may find your app a negative experience. 

# More best practices

After [the API improvements announced for this project][1], the project is going through a transition period of getting a new set of best practices. Some of the old best practices are no longer recommended and the public API is in the process of being modified to match these new best practices. 

You can view [more best practices for Wendy here][2], however, note that some of those ideas are going to be changed. 

[1]:	https://github.com/levibostian/Wendy-iOS/discussions/51
[2]:	https://github.com/levibostian/Wendy-Android/blob/master/BEST_PRACTICES.md