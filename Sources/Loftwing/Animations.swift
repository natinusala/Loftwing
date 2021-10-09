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

/// Type of animation completion callbacks.
public typealias AnimationCompletionCallback = () -> ()

/// Easing type (in, out, in-out).
public enum EasingType {
    case easeIn
    case easeOut
    case easeInOut
}

/// Easing functions.
public enum Easing {
    case quadratic(EasingType)
    case cubic(EasingType)
    case quartic(EasingType)
    case quintic(EasingType)
    case sine(EasingType)
    case circular(EasingType)
    case exponential(EasingType)
    case elastic(EasingType)
    case back(EasingType)
    case bounce(EasingType)
}

/// Builder for new float animations. Returned by the `animate()` method of animated floats.
public struct FloatAnimationBuilder {
    var animation: Animation

    /// Allows to run a callback when the animation completes.
    public mutating func then(_ callback: @escaping AnimationCompletionCallback) {
        animation.completionCallback = callback
    }
}

/// Use this property wrapper on any float value to make it animatable.
/// To access its animating methods, use the projected value with `$` operator.
@propertyWrapper
public class Animate {
    var value: Float
    var ongoingAnimation: Animation? = nil

    public init(wrappedValue: Float) {
        self.value = wrappedValue
    }

    public var wrappedValue: Float {
        return value
    }

    public var projectedValue: Animate {
        return self
    }

    /// Starts a new animation, stopping the current one if any is running.
    /// The animation starts from the given value to the target one.
    /// Do not store and use the returned FloatAnimationBuilder as the animation will start
    /// immediately after this method is called.
    public func animate(
        from initial: Float,
        to target: Float,
        during duration: Int,
        with easing: Easing
    ) -> FloatAnimationBuilder {
        // TODO: stop ongoing animation if any

        // Set initial value
        self.value = initial

        // Create a new animation
        let animation = Animation(
            targetValue: target,
            duration: duration,
            easing: easing
        )
        self.ongoingAnimation = animation

        // Enqueue the animation
        AnimationsRunner.sharedInstance.addAnimation(animation)

        // Return a builder for optional properties
        return FloatAnimationBuilder(animation: animation)
    }

    /// Starts a new animation, stopping the current one if any is running.
    /// The animation starts from the current value to the target one.
    /// Do not store and use the returned FloatAnimationBuilder as the animation will start
    /// immediately after this method is called.
    public func animate(
        to target: Float,
        during duration: Int,
        with easing: Easing
    ) -> FloatAnimationBuilder {
        return self.animate(
            from: self.value,
            to: target,
            during:duration,
            with: easing
        )
    }

    // TODO: stop animation on deinit to prevent leaks
}

/// Handle created by the animate method of an animated float, to allow
/// stopping, resetting or reversing an animation.
/// Also holds the animation state.
struct Animation {
    var targetValue: Float
    var duration: Int
    var easing: Easing

    var finished = false
    var completionCallback: AnimationCompletionCallback? = nil
}

/// Holds every ongoing animation and is responsible for running them every tick.
/// Use the sharedInstance property to get the singleton instance.
class AnimationsRunner {
    public static var sharedInstance = AnimationsRunner()

    var animations: [Animation] = []

    /// Adds the given animation to the runner.
    func addAnimation(_ animation: Animation) {
        self.animations.append(animation)
    }

    /// Runs the animations for one frame.
    func frame() {
        // To avoid mutating the running animations list while we are in the
        // loop, collect every callback to run here and run them outside of the
        // for loop (this is in case another animation gets started inside a
        // completion callback)
        var completions: [AnimationCompletionCallback] = []

        // Advance every animation

        // Collect every finished animation
    }
}
