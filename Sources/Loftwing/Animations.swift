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

import CLoftwing

/// Type of animation completion callbacks.
public typealias AnimationCompletionCallback = () -> ()

/// Type of animation ticking callbacks.
public typealias AnimationTickingCallback = (Float) -> ()

/// Returned when you start a new animation, used to set the ticking
/// and completion callbacks. Do not store the handle returned by
/// the `animate` method.
/// TODO: replace with promises
public protocol AnimationHandle {
    /// Executes the given callback when the animation completes.
    @discardableResult
    func then(callback: @escaping AnimationCompletionCallback) -> Self

    /// Executes the given callback at every frame of the animation.
    @discardableResult
    func observe(callback: @escaping AnimationTickingCallback) -> Self
}

public struct RegularAnimationHandle: AnimationHandle {
    weak var animation: Animation?

    init(for animation: Animation) {
        self.animation = animation
    }

    @discardableResult
    public func then(callback: @escaping AnimationCompletionCallback) -> Self {
        self.animation?.completionCallback = callback
        return self
    }

    @discardableResult
    public func observe(callback: @escaping AnimationTickingCallback) -> Self {
        self.animation?.tickingCallback = callback
        return self
    }
}

/// Animation handle used for animations that do not need to start.
public class NullAnimationHandle: AnimationHandle {
    @discardableResult
    public func then(callback: @escaping AnimationCompletionCallback) -> Self {
        // Immediately run the callback since the animation is already
        // completed
        callback()

        return self
    }

    @discardableResult
    public func observe(callback: @escaping AnimationTickingCallback) -> Self {
        // Nothing to do

        return self
    }
}

/// Use this property wrapper on any float value to make it animatable.
/// To access its animating methods, use the projected value with `$` operator.
@propertyWrapper
public class Animation {
    /// Current value of the animation.
    var value: Float

    /// The ticking of the currently running animation, if any.
    weak var currentTicking: AnimationTicking?

    /// Callback to be executed when the animation is completed.
    var completionCallback: AnimationCompletionCallback = {}

    /// Callback executed at every animation tick.
    var tickingCallback: AnimationTickingCallback = {_ in}

    public init(wrappedValue: Float) {
        self.value = wrappedValue
    }

    /// Returns the float value.
    public var wrappedValue: Float {
        return value
    }

    /// Returns the `Animation` reference bound to this animated
    /// float.
    public var projectedValue: Animation {
        return self
    }

    /// Starts a new animation, stopping the current one if any is running.
    /// The animation starts from the given value to the target one.
    /// Duration is in milliseconds.
    public func animate(
        from initial: Float,
        to target: Float,
        during duration: Time,
        with easing: Easing
    ) -> AnimationHandle {
        // Stop ongoing animation if any
        if let runningTicking = self.currentTicking {
            // Cancel the ticking, break the weak reference
            runningTicking.cancel()
            self.currentTicking = nil
        }

        // If target value == initial value, don't do anything
        if initial == target {
            return NullAnimationHandle()
        }

        // Reinit state
        self.value = initial
        self.completionCallback = {}
        self.tickingCallback = {_ in}

        // Create and keep a weak reference to the new animation
        let ticking = AnimationTicking(
            animation: self,
            during: duration,
            easing: easing,
            from: initial,
            target: target
        )
        self.currentTicking = ticking

        // Enqueue the new animation
        getContext().runner.addTicking(ticking)

        // Return handle
        return RegularAnimationHandle(for: self)
    }

    /// Starts a new animation, stopping the current one if any is running.
    /// The animation starts from the current value to the target one.
    /// Duration is in milliseconds.
    public func animate(
        to target: Float,
        during duration: Time,
        with easing: Easing
    ) -> AnimationHandle {
        return self.animate(
            from: self.value,
            to: target,
            during: duration,
            with: easing
        )
    }

    deinit {
        // Run our completion callback in case there is a task continuation inside
        // that we have to unlock. Regular callbacks won't be executed since it's always
        // set to {} after executing it.
        self.completionCallback()
    }
}

/// A ticking created when an animation is (re) started.
class AnimationTicking: Ticking {
    /// Bound Animation.
    weak var animation: Animation?

    /// Is the animation finished?
    var finished: Bool = false

    /// How long has the animation been running for? In nanoseconds.
    var runningFor: Time = 0

    /// The last time the frame method has been called. In nanoseconds, using
    /// the same clock as `runningFor`.
    var lastFrameTime: Time = 0

    /// Duration of the animation.
    /// Animation will be completed when `runningFor` reaches `duration`.
    let duration: Time

    let easing: Easing
    let initialValue: Float
    let targetValue: Float

    init(
        animation: Animation,
        during duration: Time,
        easing: Easing,
        from initialValue: Float,
        target targetValue: Float
    ) {
        self.animation = animation
        self.easing = easing
        self.initialValue = initialValue
        self.targetValue = targetValue

        // Convert millis duration to usec duration
        self.duration = duration * 1000
    }

    /// Runs the animation for one frame.
    func frame() {
        // Advance the animation value, run callback if finished
        if let animation = self.animation {
            // Compute time
            let now = getTimeUsec()
            let delta = self.lastFrameTime == 0 ? 0 : now - self.lastFrameTime
            self.lastFrameTime = now
            self.runningFor += delta

            // Run the easing function
            if self.runningFor >= self.duration {
                animation.value = self.targetValue
            } else {
                animation.value = self.easing.ease(
                    Float(self.runningFor),
                    self.initialValue,
                    self.targetValue - self.initialValue,
                    Float(self.duration)
                )
            }

            // Run ticking callback
            animation.tickingCallback(animation.value)

            // Handle completion
            if self.runningFor >= self.duration {
                animation.completionCallback()
                animation.completionCallback = {}

                self.finished = true
            }
        }
        // If the bound animation has been released, finish the ticking
        // without running the callback and do nothing
        else {
            self.finished = true
        }
    }

    /// Cancels the animation.
    func cancel() {
        // Run completion callback if the animation still lives
        self.animation?.completionCallback()
        self.animation?.completionCallback = {}

        // Break the weak reference, this will cause the ticking to be finished
        // at next frame.
        self.animation = nil
    }
}

/// Easing functions.
public enum Easing {
    case linear

    case quadInOut
    case quadOutIn
    case quadIn
    case quadOut

    case cubicInOut
    case cubicOutIn
    case cubicIn
    case cubicOut

    case quartInOut
    case quartOutIn
    case quartIn
    case quartOut

    case quintInOut
    case quintOutIn
    case quintIn
    case quintOut

    case sineInOut
    case sineOutIn
    case sineIn
    case sineOut

    case expoInOut
    case expoOutIn
    case expoIn
    case expoOut

    case circInOut
    case circOutIn
    case circIn
    case circOut

    case bounceInOut
    case bounceOutIn
    case bounceIn
    case bounceOut

    /// Run the easing function with given parameters.
    func ease(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
        switch self {
            case .linear:
                return easingLinear(t, b, c, d)

            case .quadInOut:
                return easingInOutQuad(t, b, c, d)
            case .quadOutIn:
                return easingOutInQuad(t, b, c, d)
            case .quadIn:
                return easingInQuad(t, b, c, d)
            case .quadOut:
                return easingOutQuad(t, b, c, d)

            case .cubicInOut:
                return easingInOutCubic(t, b, c, d)
            case .cubicOutIn:
                return easingOutInCubic(t, b, c, d)
            case .cubicIn:
                return easingInCubic(t, b, c, d)
            case .cubicOut:
                return easingOutCubic(t, b, c, d)

            case .quartInOut:
                return easingInOutQuart(t, b, c, d)
            case .quartOutIn:
                return easingOutInQuart(t, b, c, d)
            case .quartIn:
                return easingInQuart(t, b, c, d)
            case .quartOut:
                return easingOutQuart(t, b, c, d)

            case .quintInOut:
                return easingInOutQuint(t, b, c, d)
            case .quintOutIn:
                return easingOutInQuint(t, b, c, d)
            case .quintIn:
                return easingInQuint(t, b, c, d)
            case .quintOut:
                return easingOutQuint(t, b, c, d)

            case .sineInOut:
                return easingInOutSine(t, b, c, d)
            case .sineOutIn:
                return easingOutInSine(t, b, c, d)
            case .sineIn:
                return easingInSine(t, b, c, d)
            case .sineOut:
                return easingOutSine(t, b, c, d)

            case .expoInOut:
                return easingInOutExpo(t, b, c, d)
            case .expoOutIn:
                return easingOutInExpo(t, b, c, d)
            case .expoIn:
                return easingInExpo(t, b, c, d)
            case .expoOut:
                return easingOutExpo(t, b, c, d)

            case .circInOut:
                return easingInOutCirc(t, b, c, d)
            case .circOutIn:
                return easingOutInCirc(t, b, c, d)
            case .circIn:
                return easingInCirc(t, b, c, d)
            case .circOut:
                return easingOutCirc(t, b, c, d)

            case .bounceInOut:
                return easingInOutBounce(t, b, c, d)
            case .bounceOutIn:
                return easingOutInBounce(t, b, c, d)
            case .bounceIn:
                return easingInBounce(t, b, c, d)
            case .bounceOut:
                return easingOutBounce(t, b, c, d)
        }
    }
}

/// Easing functions below taken from https://github.com/EmmanuelOga/easing under MIT License.
func easingLinear(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * t / d + b
}

func easingInOutQuad(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    let t = t / d * 2
    if (t < 1) {
        return c / 2 * pow(t, 2) + b
    }
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
}

func easingInQuad(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * pow(t / d, 2) + b
}

func easingOutQuad(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    let t = t / d
    return -c * t * (t - 2) + b
}

func easingOutInQuad(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutQuad(t * 2, b, c / 2, d)
    }
    return easingInQuad((t * 2) - d, b + c / 2, c / 2, d)
}

func easingInCubic(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * pow(t / d, 3) + b
}

func easingOutCubic(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * (pow(t / d - 1, 3) + 1) + b
}

func easingInOutCubic(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    var t = t / d * 2
    if (t < 1) {
        return c / 2 * t * t * t + b
    }
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
}

func easingOutInCubic(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutCubic(t * 2, b, c / 2, d)
    }
    return easingInCubic((t * 2) - d, b + c / 2, c / 2, d)
}

func easingInQuart(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * pow(t / d, 4) + b
}

func easingOutQuart(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return -c * (pow(t / d - 1, 4) - 1) + b
}

func easingInOutQuart(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    let t = t / d * 2
    if (t < 1) {
        return c / 2 * pow(t, 4) + b
    }
    return -c / 2 * (pow(t - 2, 4) - 2) + b
}

func easingOutInQuart(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutQuart(t * 2, b, c / 2, d)
    }
    return easingInQuart((t * 2) - d, b + c / 2, c / 2, d)
}

func easingInQuint(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * pow(t / d, 5) + b
}

func easingOutQuint(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * (pow(t / d - 1, 5) + 1) + b
}

func easingInOutQuint(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    let t = t / d * 2
    if (t < 1) {
        return c / 2 * pow(t, 5) + b
    }
    return c / 2 * (pow(t - 2, 5) + 2) + b
}

func easingOutInQuint(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutQuint(t * 2, b, c / 2, d)
    }
    return easingInQuint((t * 2) - d, b + c / 2, c / 2, d)
}

func easingInSine(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return -c * cos(t / d * (Float.pi / 2)) + c + b
}

func easingOutSine(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c * sin(t / d * (Float.pi / 2)) + b
}

func easingInOutSine(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return -c / 2 * (cos(Float.pi * t / d) - 1) + b
}

func easingOutInSine(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutSine(t * 2, b, c / 2, d)
    }
    return easingInSine((t * 2) - d, b + c / 2, c / 2, d)
}

func easingInExpo(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t == 0) {
        return b
    }
    return c * powf(2, 10 * (t / d - 1)) + b - c * 0.001
}

func easingOutExpo(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t == d) {
        return b + c
    }
    return c * 1.001 * (-powf(2, -10 * t / d) + 1) + b
}

func easingInOutExpo(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t == 0) {
        return b
    }
    if (t == d) {
        return b + c
    }
    let t = t / d * 2
    if (t < 1) {
        return c / 2 * powf(2, 10 * (t - 1)) + b - c * 0.0005
    }
    return c / 2 * 1.0005 * (-powf(2, -10 * (t - 1)) + 2) + b
}

func easingOutInExpo(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutExpo(t * 2, b, c / 2, d)
    }
    return easingInExpo((t * 2) - d, b + c / 2, c / 2, d)
}

func easingInCirc(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return(-c * (sqrt(1 - powf(t / d, 2)) - 1) + b)
}

func easingOutCirc(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return(c * sqrt(1 - powf(t / d - 1, 2)) + b)
}

func easingInOutCirc(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    var t = t / d * 2
    if (t < 1) {
        return -c / 2 * (sqrt(1 - t * t) - 1) + b
    }
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
}

func easingOutInCirc(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutCirc(t * 2, b, c / 2, d)
    }
    return easingInCirc((t * 2) - d, b + c / 2, c / 2, d)
}

func easingOutBounce(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    var t = t / d
    if (t < 1 / 2.75) {
        return c * (7.5625 * t * t) + b
    }
    if (t < 2 / 2.75) {
        t = t - (1.5 / 2.75)
        return c * (7.5625 * t * t + 0.75) + b
    }
    else if (t < 2.5 / 2.75) {
        t = t - (2.25 / 2.75)
        return c * (7.5625 * t * t + 0.9375) + b
    }
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
}

func easingInBounce(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    return c - easingOutBounce(d - t, 0, c, d) + b
}

func easingInOutBounce(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingInBounce(t * 2, 0, c, d) * 0.5 + b
    }
    return easingOutBounce(t * 2 - d, 0, c, d) * 0.5 + c * 0.5 + b
}

func easingOutInBounce(_ t: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
    if (t < d / 2) {
        return easingOutBounce(t * 2, b, c / 2, d)
    }
    return easingInBounce((t * 2) - d, b + c / 2, c / 2, d)
}
