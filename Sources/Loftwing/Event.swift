/*
    Copyright 2021 natinusala

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import Foundation

/// An "event" is a channel from which you can signal something to
/// observers of that signal.
///
/// To use, first create your event. The generic type is the parameter type
/// observers get in their callback, and is also the type of the data you give
/// when you fire the event.
///
/// Then start observing the event by calling the observe(with:) async method.
///
/// When you want to fire the event (sending the signal to every observer and running
/// their callback), call the fire(_ parameter:) async method.
/// TODO: rework CallbackParameter once Swift has variadic generic parameters
class Event<CallbackParameter> {
    typealias EventTaskHandle = TaskHandle<Void, Never>
    typealias ObserverCallback = (CallbackParameter) async -> ()

    var observers: [ObserverCallback] = []
    var tasks: [EventTaskHandle] = []

    /// Fires the event, sending a signal to every observer. Their callback
    /// will be executed with the given parameters.
    /// Returns true if there is at least one observer for this event.
    @discardableResult
    public func fire() async -> Bool where CallbackParameter == Void {
        return await self.fire(with: ())
    }

    /// Fires the event, sending a signal to every observer. Their callback
    /// will be executed with the given parameters.
    /// Returns true if there is at least one observer for this event.
    @discardableResult
    public func fire(with parameter: CallbackParameter) async -> Bool {
        if self.observers.isEmpty {
            Logger.debug(debugEvents, "Dropping firing of event because there are no observers")
            return false
        }

        Logger.debug(debugEvents, "Firing event")

        // Start a task for every observer
        let queue = TaskQueue.sharedInstance
        for observer in self.observers {
            self.tasks.append(
                await queue.addTask(
                    finishCallback: { finished in
                        // Remove task from tracked handlers
                        self.tasks.removeFirst(finished)
                        Logger.debug(debugEvents, "Removed handle of task \(finished.uuid) from event tracked tasks")
                    },
                    operation: {
                        await observer(parameter)
                    }
                )
            )
        }

        Logger.debug(debugEvents, "Started \(self.observers.count) task(s) for \(self.observers.count) observer(s)")

        return true
    }

    /// Starts observing the event. The given callback will be executed asynchronously
    /// whenever someone fires the event.
    public func observe(with callback: @escaping ObserverCallback) {
        Logger.debug(debugEvents, "Added a new event observer")
        self.observers.append(callback)
    }
}

/// The status of a task created when an event is fired.
enum TaskState {
    case running /// the task is running (initial state)
    case finished /// the task has finished gracefully, the handle is waiting to be collected
    case cancelRequested /// someone has requested for the task to cancel, waiting for the TaskQueue to actually cancel it
    case cancelling /// TaskQueue has cancelled the task, waiting for the code inside to stop and it will be collected
}

/// The handle to a task created when an event is fired. The task is submitted to the
/// TaskQueue, which creates a TaskHandle object and starts tracking it.
///
/// The event is the only one owning its handles, everything else must use weak pointers
/// so that when the event dies (its activity / view is closed...), the refcounting
/// also kills every task handle it has. This triggers the deinit method, which cancels
/// the underlying taks if it's running.
///
/// Other than that, a TaskHandle is a state machine handled by the TaskQueue singleton.
/// Every frame of every app, TaskQueue manages the lifecycle of every running task.
///
/// It's important that the main thread sleeps from time to time to give time to tasks
/// to run. If not, they will never finish and the app will eventually softlock.
actor TaskHandle<Success, Failure>: Equatable where Failure: Error {
    let uuid = UUID()

    var status: TaskState = .running
    var task: Task<Success, Failure>? = nil

    /// A callback executed when the task is finished. Not executed when the task
    /// is cancelled (we assume the task handle owner to be dead or dying).
    var finishCallback: ((TaskHandle) -> ())? = nil

    /// Returns true if the task is cancelled (so if the running code is supposed
    /// to stop or not)
    var cancelled: Bool {
        return self.task?.isCancelled ?? false
    }

    /// Sets the task status.
    func setStatus(_ status: TaskState) {
        self.status = status
    }

    /// Creates a new TaskHandle with given finish callback and operation.
    init(
        finishCallback: ((TaskHandle) -> ())?,
        operation: @escaping () async -> Success
    ) async where Failure == Never {
        self.finishCallback = finishCallback

        /// Create the underlying task, which will be executed
        /// right after its creation.
        self.task = Task<Success, Failure> {
            // Run the task
            Logger.debug(debugEvents, "Executing task \(self.uuid) callback")
            let result = await operation()

            // Set status to finished
            await self.setStatus(.finished)
            Logger.debug(debugEvents, "Task \(self.uuid) set to finished")

            return result
        }
    }

    deinit {
        // TODO: make sure this actually works (when an activity / view is closed, all its events must stop)

        Logger.debug(debugEvents, "Deinit called on task \(self.uuid)")

        // If we are still running, it means the event owning us has been
        // deinited, so we have to cancel the task and drop everything
        if self.status == .running {
            Logger.debug(debugEvents, "Cancelling task \(self.uuid) due to Event deinit")
            self.status = .cancelling
            if let task = self.task {
                task.cancel()
            }
        }
    }

    public static func == (lhs: TaskHandle, rhs: TaskHandle) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

/// TaskQueue is the singleton that manages the lifecycle of every running
/// TaskHandle. The collect() method is called every frame to collect finished
/// tasks and cancel tasks that should be cancelled.
///
/// Use the sharedInstance property to get the singleton instance.
class TaskQueue {
    public static var sharedInstance = TaskQueue()

    typealias Success = Void
    typealias Failure = Never
    typealias WeakHandle = Weak<TaskHandle<Success, Failure>>

    var tasks: [Weak<TaskHandle<Success, Failure>>] = []

    private init() {}

    /// Adds the given task to the queue, returning its handle. As the queue only
    /// stores a weak pointer, you have to store the returned handle somewhere
    /// to own it otherwise the task will be cancelled right away.
    func addTask(
        finishCallback: ((TaskHandle<Success, Failure>) -> ())?,
        operation: @escaping () async -> Success
    ) async -> TaskHandle<Success, Failure> {
        let handle = await TaskHandle(
            finishCallback: finishCallback,
            operation: operation
        )

        // Add handle to the list of known tasks
        self.tasks.append(WeakHandle(value: handle))

        return handle
    }

    /// Asks for cancellation of the given handle. Cancellation is cooperative
    /// so it may not cancel immediately (or ever).
    func cancelTask(_ handle: TaskHandle<Success, Failure>) async {
        if await handle.status == .running {
            await handle.setStatus(.cancelRequested)
        }
    }

    /// Collects finished tasks, running their finished callback, and cancels
    /// all tasks with pending cancellation.
    func collect() async {
        // Remove every finished, cancelled and dead tasks
        var newTasks: [WeakHandle] = []
        for task in self.tasks {
            // Check if the weak ptr is still valid
            // This also gets a "strong" pointer to the task while we need it
            // since the finished callback
            // might destroy the task (we are only holding weak references)
            if let handle = task.value {
                let isFinished = await handle.status == .finished
                let isCancelled = await handle.cancelled

                if !isFinished && !isCancelled {
                    newTasks.append(task)
                } else {
                    // Run the "finish callback"
                    Logger.debug(debugEvents, "Running task \(handle.uuid) finished callback")
                    if let cb = await handle.finishCallback {
                        cb(handle)
                    }

                    Logger.debug(debugEvents, "Task \(handle.uuid) finished")
                }
            }

            self.tasks = newTasks
        }

        // Cancel all tasks that need to be cancelled
        for weakHandle in self.tasks {
            // Ensure the handle is still valid
            // If not, it will be collected on next frame
            if let handle = weakHandle.value {
                // This can fail if we don't have a handle to the current task yet
                // in which case the cancel will be retried at next collect call
                if await handle.status == .cancelRequested {
                    if let task = await handle.task {
                        task.cancel()
                        await handle.setStatus(.cancelling)
                        Logger.debug(debugEvents, "Requested cancellation of task \(handle.uuid)")
                    }
                }
            }
        }
    }
}
