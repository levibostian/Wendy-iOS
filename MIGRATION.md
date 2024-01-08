# Migration docs 

## v1 to v2 - Removal of manually running tasks 

The breaking change that caused Wendy to go from v1 to v2 is the removal of a feature known as *manually run tasks*. The idea behind this feature was to make Wendy a generic job scheduler for your app that could either run all of your tasks for you and you could manage some yourself. 

[The maintainers of Wendy decided to bring focus back to Wendy](https://github.com/levibostian/Wendy-iOS/discussions/51) and make it really good at one thing. In order to bring this focus, this feature of manually running a task does not add value to the project. 

If your app currently uses this feature, the recommended migration path is to no longer use Wendy to run the jobs in your app you're manually managing. Wendy does not provide an alternative feature inside of it that can be used as an alternative. Either write code yourself to run these tasks or use a 3rd party SDK to run these jobs. 

