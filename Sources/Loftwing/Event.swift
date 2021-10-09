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

/// An "event" is a channel from which you can signal something to
/// observers of that signal.
///
/// To use, first create your event. The generic type is the parameter type
/// observers get in their callback, and is also the type of the data you give
/// when you fire the event.
///
/// Then start observing the event by calling the observe(with:) method.
///
/// When you want to fire the event (sending the signal to every observer and running
/// their callback), call the fire(_ parameter:) method.
/// TODO: rework CallbackParameter once Swift has variadic generic parameters
class Event<CallbackParameter> {
    typealias ObserverCallback = (CallbackParameter) async -> ()

    var observers: [ObserverCallback] = []

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
            return false
        }

        // Add a ticking for every observer
        let runner = await getContext().runner

        for observer in self.observers {
            Logger.debug(debugEvents, "Firing event for \(self.observers.count) observers")
            runner.addTicking(EventTicking<CallbackParameter, Void, Error>(event: self) {
                await observer(parameter)
            })
        }

        return true
    }

    /// Starts observing the event. The given callback will be executed asynchronously
    /// whenever someone fires the event.
    public func observe(with callback: @escaping ObserverCallback) {
        self.observers.append(callback)
    }
}

/// A ticking related to an event, created when the event is fired.
/// It holds a weak reference to the event - when the event is deinited, the ticking
/// and its underlying task are automatically stopped.
/// The ticking acts as a lifecycle manager for the underlying task, it never
/// executes anything.
class EventTicking<CallbackParameter, Success, Failure>: Ticking where Failure: Error {
    typealias EventTask = Task<Success, Failure>

    /// Weak reference to the associated event.
    let event: Weak<Event<CallbackParameter>>

    /// The underlying task. Must be optional and set to nil in case we use it
    /// before it's actually set (cannot use self until all properties are set).
    var task: EventTask? = nil

    /// Is the underlying task finished or cancelled? This is a one-way boolean (false -> true)
    /// to avoid data races and avoid the need for an actor (which is possible but would add
    /// another layer to the events / tasks stack).
    var finished = false {
        willSet(newValue) {
            if self.finished && !newValue {
                fatalError("Event ticking has already been finished")
            }
        }
    }

    init(
        event: Event<CallbackParameter>,
        operation: @escaping () async -> Success
    ) where Failure == Error {
        self.event = Weak(value: event)

        // Start the task
        self.task = EventTask {
            // Run the actual task
            Logger.debug(debugEvents, "Running event task")
            let result = await operation()

            // Set state to finished
            Logger.debug(debugEvents, "Event ticking marked as finished")
            self.finished = true

            return result
        }
    }

    func frame() {
        // Don't do anything if the task is already finished
        if self.finished {
            return
        }

        // Check if the event has been deinited, in which case cancel the task
        // We have to trust that it's actually cancelling, but since it's cooperative
        // there is not much we can do to guarantee cancellation.
        if self.event.value == nil {
            // If the task is not set (yet), just wait for the next frame to
            // collect it
            if let task = self.task {
                Logger.debug(debugEvents, "Event bound to task was deinited, cancelling task")
                task.cancel()
                self.finished = true
            } else {
                Logger.debug(debugEvents, "Event bound to task was deinited but task not handle not available yet")
            }
        }
    }
}
