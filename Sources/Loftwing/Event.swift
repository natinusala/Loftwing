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

import Async

/// An observer is the combination of a callback and its owner.
/// The observer only keeps a weak reference to the owner. This allows
/// automatically unregistering the observer once the owner gets released.
public class Observer<CallbackParameter> {
    public typealias Callback = (CallbackParameter) -> ()
    public typealias Owner = AnyObject

    let callback: Callback
    weak var owner: Owner?

    init(owner: Owner, callback: @escaping Callback) {
        self.callback = callback
        self.owner = owner
    }
}

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
///
/// Events are executed on the main thread.
/// TODO: rework CallbackParameter once Swift has variadic generic parameters
public class Event<CallbackParameter> {
    public typealias ObserverType = Observer<CallbackParameter>

    var observers: [ObserverType] = []

    public init() {}

    /// Fires the event, sending a signal to every observer. Their callback
    /// will be executed with the given parameters.
    /// Returns true if there is at least one observer for this event.
    @discardableResult
    public func fire() -> Bool where CallbackParameter == Void {
        return self.fire(with: ())
    }

    /// Fires the event, sending a signal to every observer. Their callback
    /// will be executed with the given parameters.
    /// Returns true if there is at least one observer for this event.
    @discardableResult
    public func fire(with parameter: CallbackParameter) -> Bool {
        if self.observers.isEmpty {
            return false
        }

        // Execute callbacks
        for observer in self.observers {
            if observer.owner != nil {
                Logger.debug(debugEvents, "Firing event for \(self.observers.count) observers")
                Async.main {
                    observer.callback(parameter)
                }
            }
            else {
                Logger.debug(debugEvents, "Observer owner has been released, not firing the event")
            }
        }

        // Lazily remove every observer with a released owner
        // TODO: test that this actually works
        self.observers = self.observers.filter { $0.owner != nil }

        return true
    }

    /// Starts observing the event.
    /// The owner is used to automatically remove the observer when the owner gets
    /// released (we keep a weak reference to the owner to do so).
    public func observe(
        owner: ObserverType.Owner,
        with callback: @escaping ObserverType.Callback)
    {
        self.observers.append(Observer(owner: owner, callback: callback))
    }
}

/// Use this property wrapper to add a "value changed" event to anything.
/// This is useful for reactive UI development.
@propertyWrapper
public class Observable<T> {
    public typealias EventType = Event<T>

    public var value: T {
        didSet {
            Logger.debug(debugEvents, "Observable \(self) value changed, firing event")
            self.valueChangedEvent.fire(with: self.value)
        }
    }

    let valueChangedEvent = EventType()

    public init(wrappedValue: T) {
        self.value = wrappedValue
    }

    public var wrappedValue: T {
        get { return self.value }
        set { self.value = newValue }
    }

    public var projectedValue: Observable<T> {
        return self
    }

    /// Starts observing for changes of the wrapped value.
    public func observe(
        owner: EventType.ObserverType.Owner,
        with callback: @escaping EventType.ObserverType.Callback
    ) {
        self.valueChangedEvent.observe(owner: owner, with: callback)
    }
}
