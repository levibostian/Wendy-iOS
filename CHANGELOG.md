## [0.5.1] - 2020-12-18

### Fixed
- Compile with XCode 12.2

## [0.5.0] - 2019-12-23

### Added
- Constructors to create instances for internal classes for testing purposes. 

### Fixed 
- `PendingTasksRunnerResult` properties now public 

## [0.4.1] - 2019-12-23

### Fixed
- `PendingTaskError` properties now public

## [0.4.0] - 2019-12-21

### Added
- Collections! Be able to run groups of different `PendingTask`s together to keep your app stable. 

### Changed
- **Breaking Change**: `PendingTaskFactory.getTask()` no longer can return optional. 
- **Breaking Change**: Wendy `runTask` functions now require a completion handler. 
- **Breaking Change**: Change task listeners. Adding a `cancelled` case. 

## [0.3.0] - 2019-12-17

### Added
- Add method to clear Wendy data. Use if the user of your app logs out, for example. 

### Changed
- **Breaking Change**: Simplified background fetch method call. 
- Update travis and cocoapods config to be faster with modern updates. 

## [0.2.0-alpha] - 2019-07-24

Swift5, XCode 10.2 support

## [0.1.0-alpha] - 2018-04-25
First public release of Wendy for iOS! 

### Added
- Built task runner to run tasks added to Wendy library.
- Add ability for developer to add tasks to Wendy to run in the future.
- Tasks can be chained together into groups to succeed in a certain order. 
- Set tasks to manually run instead of being run by the task runner.
- Dynamically decide at runtime if a task can run by the task runner or not.
- Register listeners with Wendy to receive status updates on a task or the runner.
- Add getting started docs to the README.md file.
- Add error recording utility to Wendy when user errors occur in your app.
