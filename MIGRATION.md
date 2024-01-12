# Migration docs

## v1 to v2 - Removal of manually running tasks

The breaking change that caused Wendy to go from v1 to v2 is the removal of a feature known as *manually run tasks*. The idea behind this feature was to make Wendy a generic job scheduler for your app that could either run all of your tasks for you and you could manage some yourself. 

[The maintainers of Wendy decided to bring focus back to Wendy][1] and make it really good at one thing. In order to bring this focus, this feature of manually running a task does not add value to the project. 

If your app currently uses this feature, the recommended migration path is to no longer use Wendy to run the jobs in your app you're manually managing. Wendy does not provide an alternative feature inside of it that can be used as an alternative. Either write code yourself to run these tasks or use a 3rd party SDK to run these jobs. 

# v2 to v3 - Removal of Collections feature 

The breaking change that caused Wendy to go from v2 to v3 is the removal of a feature known as *Collections*. This feature was originally added to satisfy an old best practice that was recommended at the time. However, this best practice is no longer recommended. Because of that, Collections has been removed to encourage the new best practice instead.  

If your app currently uses this feature, the recommended migration path is to modify your app’s logic to [follow this new best practice][2]. 

[1]:	https://github.com/levibostian/Wendy-iOS/discussions/51
[2]:	BEST_PRACTICES.md#after-i-add-a-task-to-wendy-what-updates-should-i-make-to-my-apps-local-data-storage