import Foundation
import Semaphore

public extension Wendy {
    var currentlyRunningTask: PendingTask? {
        PendingTasksRunner.DataStore.shared.getDataSnapshot().currentlyRunningTask
    }
}

/*
 Requirements of the task runner:

 1. when you call `Wendy.runTask()` it returns instantly to you. It does *not* block the calling thread. It's like it schedules a job to run in the future.
 2. X number of threads all running the task runner's `runTask()` function can only run one at a time. (so, run runTask() in a sync way)
 3. The task runner's `runTask()` runs in a sync way (while the `PendingTask.runTask()` is async) where it does not return a result until the task has failed or succeeded. So, work in a blocking way.
 */
// sourcery: InjectRegister = "PendingTasksRunner"
public final class PendingTasksRunner: Sendable, Singleton {
    public static let shared = PendingTasksRunner()

    private var pendingTasksManager: PendingTasksManager { inject.pendingTasksManager }
    private var taskRunner: WendyTaskRunner? { inject.taskRunner }

    private let runAllTasksLock = RunAllTasksLock()
    private let runTaskSemaphore = AsyncSemaphore(value: WendyConfig.semaphoreValue)
    private let runningGroups = RunningGroups()

    public func reset() {}

    /**
     Runs 1 task and returns the result.

     Guarantees:
     * Will only run 1 task at a time. Your request may need to wait in order for it to begin running. The function call will return after the wait period + time it took to run the task.
     * Runs the request in a background thread.
     */
    func runTask(taskId: Double) async -> TaskRunResult {
        guard let taskRunner else {
            return .cancelled
        }

        await runTaskSemaphore.wait()

        // Allow the runner to be cancelled between executing tasks.
        if Task.isCancelled {
            runTaskSemaphore.signal()
            return .cancelled
        }

        guard let taskToRun = pendingTasksManager.getTaskByTaskId(taskId) else {
            runTaskSemaphore.signal()
            return .cancelled
        }

        if !PendingTasksUtil.isTaskValid(taskId: taskId) {
            LogUtil.d("Task: \(taskToRun.describe()) is cancelled. Deleting the task.")
            pendingTasksManager.delete(taskId: taskId)
            LogUtil.logTaskComplete(taskToRun, successful: true, cancelled: true)

            runTaskSemaphore.signal()
            return .cancelled
        }

        dataStore.updateDataBlock { data in
            data.currentlyRunningTask = taskToRun
        }

        LogUtil.logTaskRunning(taskToRun)
        LogUtil.d("Running task: \(taskToRun.describe())")

        do {
            try await taskRunner.runTask(tag: taskToRun.tag, data: taskToRun.data)

            dataStore.updateDataBlock { data in
                data.currentlyRunningTask = nil
            }

            LogUtil.d("Task: \(taskToRun.describe()) ran successful.")
            LogUtil.d("Deleting task: \(taskToRun.describe()).")
            pendingTasksManager.delete(taskId: taskId)
            LogUtil.logTaskComplete(taskToRun, successful: true, cancelled: false)

            runTaskSemaphore.signal()
            return .successful
        } catch {
            dataStore.updateDataBlock { data in
                data.currentlyRunningTask = nil
            }

            LogUtil.d("Task: \(taskToRun.describe()) failed but will reschedule it. Skipping it.")
            LogUtil.logTaskComplete(taskToRun, successful: false, cancelled: false)

            runTaskSemaphore.signal()
            return .failure(error: error)
        }
    }

    /// Actor to manage scheduling state for group and ungrouped tasks in a concurrency-safe way.
    final actor Scheduler {
        typealias GroupID = String
        typealias TaskIndex = Int
        private var groupNextIndex = [GroupID: Int]()
        private var ungroupedNextIndex = 0
        private var scheduled = Set<TaskIndex>()
        let groupTasks: [GroupID: [TaskIndex]]
        let ungroupedTasks: [TaskIndex]
        init(groupTasks: [GroupID: [TaskIndex]], ungroupedTasks: [TaskIndex]) {
            self.groupTasks = groupTasks
            self.ungroupedTasks = ungroupedTasks
        }
        /// Returns the next unscheduled task index for a group, or nil if done.
        func nextGroupTaskIndex(_ groupId: GroupID) -> TaskIndex? {
            let idx = groupNextIndex[groupId, default: 0]
            guard let tasks = groupTasks[groupId], idx < tasks.count else { return nil }
            return tasks[idx]
        }
        /// Advances the group index after a task completes.
        func advanceGroup(_ groupId: GroupID) {
            groupNextIndex[groupId, default: 0] += 1
        }
        /// Returns the next unscheduled ungrouped task index, or nil if done.
        func nextUngroupedTaskIndex() -> TaskIndex? {
            guard ungroupedNextIndex < ungroupedTasks.count else { return nil }
            return ungroupedTasks[ungroupedNextIndex]
        }
        /// Advances the ungrouped index after a task completes.
        func advanceUngrouped() {
            ungroupedNextIndex += 1
        }
        /// Marks a task index as scheduled.
        func markScheduled(_ idx: TaskIndex) {
            scheduled.insert(idx)
        }
        /// Returns true if a task index has already been scheduled.
        func isScheduled(_ idx: TaskIndex) -> Bool {
            scheduled.contains(idx)
        }
    }

    /// Gathers all tasks to run, in order, applying the filter.
    private func gatherTasks(filter: RunAllTasksFilter?) -> [PendingTask] {
        var lastSuccessfulOrFailedTaskId: Double = 0
        var allTasks: [PendingTask] = []
        while let nextTask = pendingTasksManager.getNextTaskToRun(lastSuccessfulOrFailedTaskId, filter: filter) {
            lastSuccessfulOrFailedTaskId = nextTask.taskId!
            allTasks.append(nextTask)
        }
        return allTasks
    }

    /// Builds group and ungrouped task indices from the list of tasks.
    private func buildTaskIndices(tasks: [PendingTask]) -> ([Scheduler.GroupID: [Scheduler.TaskIndex]], [Scheduler.TaskIndex]) {
        let groupTasks = tasks.enumerated().reduce(into: [Scheduler.GroupID: [Scheduler.TaskIndex]]()) { dict, pair in
            let (idx, task) = pair
            if let groupId = task.groupId {
                dict[groupId, default: []].append(idx)
            }
        }
        let ungroupedTasks = tasks.enumerated().compactMap { (idx, task) in task.groupId == nil ? idx : nil }
        return (groupTasks, ungroupedTasks)
    }

    /// Schedules and runs all tasks using the provided indices and scheduler.
    private func scheduleAndRunTasks(
        allTasks: [PendingTask],
        groupTasks: [Scheduler.GroupID: [Scheduler.TaskIndex]],
        ungroupedTasks: [Scheduler.TaskIndex],
        scheduler: Scheduler,
        state: TaskSchedulerState,
        semaphore: AsyncSemaphore,
        failedTasksGroups: FailedGroups,
        runAllTasksResultBox: RunAllTasksResultBox
    ) async {
        await withTaskGroup(of: (Scheduler.GroupID?, Scheduler.TaskIndex?).self) { group in
            // Schedule the first task for each group
            for groupId in groupTasks.keys {
                if let idx = await scheduler.nextGroupTaskIndex(groupId) {
                    await scheduler.markScheduled(idx)
                    group.addTask { (groupId, idx) }
                }
            }
            // Schedule the first ungrouped tasks up to the semaphore limit
            for _ in 0..<min(WendyConfig.semaphoreValue, ungroupedTasks.count) {
                if let idx = await scheduler.nextUngroupedTaskIndex() {
                    await scheduler.markScheduled(idx)
                    group.addTask { (nil, idx) }
                }
            }

            // As each task completes, schedule the next eligible one
            for await (groupId, idx) in group {
                guard let idx = idx else { continue }
                await semaphore.wait()
                let task = await state.getTask(at: idx)
                let (_, result) = await self.runGroupAwareTask(task, failedTasksGroups: failedTasksGroups)
                await runAllTasksResultBox.addResult(result)
                if let groupId = task.groupId, case .failure = result {
                    await failedTasksGroups.insert(groupId)
                }
                if let groupId = task.groupId, case .skipped = result {
                    LogUtil.logTaskSkipped(task, reason: ReasonPendingTaskSkipped.partOfFailedGroup)
                    LogUtil.d("Task: \(task.describe()) belongs to a failing group of tasks. Skipping it.")
                }
                if let groupId = task.groupId, !(await failedTasksGroups.contains(groupId)) {
                    await scheduler.advanceGroup(groupId)
                    if let nextIdx = await scheduler.nextGroupTaskIndex(groupId) {
                        await scheduler.markScheduled(nextIdx)
                        group.addTask { (groupId, nextIdx) }
                    }
                } else if groupId == nil {
                    await scheduler.advanceUngrouped()
                    if let nextIdx = await scheduler.nextUngroupedTaskIndex() {
                        await scheduler.markScheduled(nextIdx)
                        group.addTask { (nil, nextIdx) }
                    }
                }
                semaphore.signal()
            }
        }
    }

    /// Runs all tasks, allowing a filter to skip running some tasks.
    /// - Guarantees:
    ///   * Runs on a background thread.
    ///   * Runs all tasks in a serial or parallel way, preserving group order.
    ///   * Only 1 runner is running at a time. If a runner is already running, this request will be ignored and returned instantly.
    func runAllTasks(filter: RunAllTasksFilter?) async -> PendingTasksRunnerResult {
        if await runAllTasksLock.requestToRunAllTasks() == false {
            return .new()
        }

        let runAllTasksResultBox = RunAllTasksResultBox(PendingTasksRunnerResult.new())
        let failedTasksGroups = FailedGroups()
        let allTasks = gatherTasks(filter: filter)
        let (groupTasks, ungroupedTasks) = buildTaskIndices(tasks: allTasks)
        let state = TaskSchedulerState(allTasks: allTasks, groupTasks: groupTasks, ungroupedTasks: ungroupedTasks)
        let semaphore = AsyncSemaphore(value: WendyConfig.semaphoreValue)
        let scheduler = Scheduler(groupTasks: groupTasks, ungroupedTasks: ungroupedTasks)

        await scheduleAndRunTasks(
            allTasks: allTasks,
            groupTasks: groupTasks,
            ungroupedTasks: ungroupedTasks,
            scheduler: scheduler,
            state: state,
            semaphore: semaphore,
            failedTasksGroups: failedTasksGroups,
            runAllTasksResultBox: runAllTasksResultBox
        )

        LogUtil.d("All done running tasks.")
        LogUtil.logAllTasksComplete()

        await runAllTasksLock.unlock()

        return await runAllTasksResultBox.get()
    }

    private func runGroupAwareTask(_ task: PendingTask, failedTasksGroups: FailedGroups) async -> (PendingTask, TaskRunResult) {
        let groupId = task.groupId
        if let groupId = groupId {
            // Check if group is already failed before running
            if await failedTasksGroups.contains(groupId) {
                return (task, .skipped(reason: .partOfFailedGroup))
            }
            while await runningGroups.contains(groupId) {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            await runningGroups.insert(groupId)
        }
        var result: TaskRunResult
        if let groupId = groupId, await failedTasksGroups.contains(groupId) {
            result = .skipped(reason: .partOfFailedGroup)
        } else {
            result = await runTask(taskId: task.taskId!)
        }
        // If the task failed, mark the group as failed before releasing the group lock
        if let groupId = groupId, case .failure = result {
            await failedTasksGroups.insert(groupId)
        }
        if let groupId = groupId {
            Task { await runningGroups.remove(groupId) }
        }
        return (task, result)
    }

    actor RunAllTasksLock {
        private var isRunningAllTasks = false

        func requestToRunAllTasks() async -> Bool {
            if isRunningAllTasks {
                return false
            }

            isRunningAllTasks = true
            return true
        }

        func unlock() {
            isRunningAllTasks = false
        }
    }

    actor RunningGroups {
        private var groups = Set<String>()
        func contains(_ group: String) -> Bool { groups.contains(group) }
        func insert(_ group: String) { groups.insert(group) }
        func remove(_ group: String) { groups.remove(group) }
    }

    actor FailedGroups {
        private var groups = Set<String>()
        func contains(_ group: String) -> Bool { groups.contains(group) }
        func insert(_ group: String) { groups.insert(group) }
    }

    actor RunAllTasksResultBox {
        var value: PendingTasksRunnerResult
        init(_ initial: PendingTasksRunnerResult) { self.value = initial }
        func addResult(_ result: TaskRunResult) {
            value = value.addResult(result)
        }
        func get() -> PendingTasksRunnerResult { value }
    }

    actor TaskSchedulerState {
        var groupNextIndex = [String: Int]()
        var ungroupedNextIndex = 0
        var scheduled = Set<Int>()
        let allTasks: [PendingTask]
        let groupTasks: [String: [Int]]
        let ungroupedTasks: [Int]
        init(allTasks: [PendingTask], groupTasks: [String: [Int]], ungroupedTasks: [Int]) {
            self.allTasks = allTasks
            self.groupTasks = groupTasks
            self.ungroupedTasks = ungroupedTasks
        }
        func getTask(at idx: Int) -> PendingTask { allTasks[idx] }
        func isScheduled(_ idx: Int) -> Bool { scheduled.contains(idx) }
        func markScheduled(_ idx: Int) { scheduled.insert(idx) }
        func getGroupNextIndex(_ groupId: String) -> Int { groupNextIndex[groupId, default: 0] }
        func incrementGroupNextIndex(_ groupId: String) { groupNextIndex[groupId, default: 0] += 1 }
        func getUngroupedNextIndex() -> Int { ungroupedNextIndex }
        func incrementUngroupedNextIndex() { ungroupedNextIndex += 1 }
    }

    public struct Data: AutoResettable {
        var currentlyRunningTask: PendingTask?
    }

    final class DataStore: InMemoryDataStore<Data>, Singleton {
        static let shared: DataStore = .init(data: .init())
    }
}
