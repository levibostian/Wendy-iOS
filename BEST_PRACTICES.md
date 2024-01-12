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

# More best practices

After [the API improvements announced for this project][1], the project is going through a transition period of getting a new set of best practices. Some of the old best practices are no longer recommended and the public API is in the process of being modified to match these new best practices. 

You can view [more best practices for Wendy here][2], however, note that some of those ideas are going to be changed. 

[1]:	https://github.com/levibostian/Wendy-iOS/discussions/51
[2]:	https://github.com/levibostian/Wendy-Android/blob/master/BEST_PRACTICES.md