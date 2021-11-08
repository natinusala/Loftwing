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

/// A Loftwing application. As the library is designed to make fullscreen,
/// single window / kiosk apps, running multiple apps per executable target is not
/// supported.
///
/// To use, create a struct that conforms to that protocol and add the `@main`
/// attribute.
open class Application: Context {
    let clearPaint = Paint(color: Color.black)

    var platform: Platform?

    public let runner = Runner()

    let activitiesStackLayer = ActivitiesStackLayer()
    var layers: [Layer] = []

    var exitRequested = false

    public var window: Window? {
        return self.platform?.window
    }

    public var colorSpace: OpaquePointer? {
        return self.window?.colorSpace
    }

    public var skContext: OpaquePointer? {
        return self.window?.skContext
    }

    public required init() throws {
        // Initialize platform
        self.platform = try platformCreator.createPlatform(
            initialWindowMode: self.initialWindowMode,
            initialGraphicsAPI: self.graphicsAPI,
            initialTitle: self.title,
            resetContext: self.resetGraphicsContextOnFrame
        )

        // Create layers
        self.layers = [
            self.activitiesStackLayer
            // TODO: OverlayLayer, which is a subclass of ViewLayer
        ]

        // Insert content layer
        if let contentLayer = self.contentLayer {
            self.layers.insert(contentLayer, at: 0)
        }

        // Register ourself as the running context
        contextSharedInstance = self

        // Push main activity
        self.activitiesStackLayer.push(activity: self.mainActivity)

        // Resize every layer
        if let window = self.window {
            for layer in self.layers {
                layer.resizeToFit(width: window.width, height: window.height)
            }
        }

        // Fire the creation event when everything is ready
        self.onCreate()
    }

    /// Executed every frame.
    func frame() {
        if let window = self.window {
            // Clear in black
            window.canvas.drawPaint(self.clearPaint)

            // Draw layers
            for layer in self.layers {
                // TODO: saveLayer and restore?
                layer.frame(canvas: window.canvas)
            }

            // Swap buffers
            window.swapBuffers()
        }

        // Run runner for one frame
        self.runner.frame()
    }

    /// Runs the app.
    public func run() {
        while true {
            // Poll platform, see if we should exit
            // TODO: handle ctrlc to gracefully exit
            if self.shouldExit() {
                // Exit
                Logger.info("Exiting...")
                self.onExit()
                break
            }

            let beginFrameTime = Date()

            // Run one frame
            self.frame()

            // Consume main queue (events, background tasks completion handlers...)
            drainMainQueue()

            // Sleep for however much time is needed
            if self.frameTime > 0 {
                let endFrameTime = Date()
                let currentFrameTime = beginFrameTime.distance(to: endFrameTime)
                var sleepAmount: TimeInterval = 0

                // Only sleep if the frame took less time to render
                // than desired frame time
                if currentFrameTime < self.frameTime {
                    sleepAmount = self.frameTime - currentFrameTime
                }

                if sleepAmount > 0 {
                    Thread.sleep(forTimeInterval: sleepAmount)
                }
            }
        }
    }

    /// Requests the application to be exited.
    public func exit() {
        self.exitRequested = true
    }

    /// Called when the app exits.
    open func onExit() {
        // Nothing by default
    }

    /// Returns `true` if the app should exit.
    func shouldExit() -> Bool {
        return (self.platform?.poll() ?? false) || self.exitRequested
    }

    /// Application title.
    open var title: String {
        "Loftwing App"
    }

    /// Initial window mode.
    open var initialWindowMode: WindowMode {
        .borderlessWindow
    }

    /// Initial graphics context.
    open var graphicsAPI: GraphicsAPI {
        return GraphicsAPI.findFirstAvailable()
    }

    /// The first activity started by the application.
    open var mainActivity: Activity {
        EmptyActivity()
    }

    /// The layer containing the "content" of your app: a game, a video player...
    /// It will be placed under the activities layer.
    open var contentLayer: Layer? {
        nil
    }

    /// Set to `true` to reset the graphics context before every frame.
    /// Useful if you are using raw OpenGL calls in your application that can clash
    /// with Loftwing rendering.
    open var resetGraphicsContextOnFrame: Bool {
        false
    }

    /// Method called when the application is fully created and ready to run.
    /// More precisely, this is called after init and before the very first frame.
    open func onCreate() {
        // Nothing by default
    }

    /// Delay between two frames, in seconds.
    /// Use 0 to have no delay and run frames as fast
    /// as possible (will take all CPU if you don't use your own
    /// frame pacing method).
    open var frameTime: Double {
        return 0.016666666 // 60FPS
    }
}

/// The "context" of an app can be retrieved from anywhere using `getContext().
/// Contains app state, metadata and useful "managers".
public protocol Context {
    var runner: Runner { get }
    var colorSpace: OpaquePointer? { get }
    var graphicsAPI: GraphicsAPI { get }
    var skContext: OpaquePointer? { get }
    var window: Window? { get }
}

/// Responsible for running "tickings" every frame as well as managing their
/// lifecycle.
public class Runner {
    var tickings: [Ticking] = []

    /// Is the runner currently inside the `frame()` method?
    var insideFrame = false

    /// Every ticking added while another ticking is in its `frame()` method.
    var newTickings: [Ticking] = []

    /// Adds a new ticking to the runner loop.
    public func addTicking(_ ticking: Ticking) {
        // Ensure the ticking isn't already in
        for t in self.tickings {
            if t === ticking {
                return
            }
        }

        // If we are inside our own `frame()` method, add them to the temporary
        // list to avoid mutating the list as we iterate over it, and to avoid
        // running the new ticking for one more frame than necessary (causes jitters).
        if self.insideFrame {
            self.newTickings.append(ticking)
        }
        else {
            self.tickings.append(ticking)
        }
    }

    /// Run every frame to run tickings and collect finished ones.
    func frame() {
        self.insideFrame = true

        // Run every ticking
        for ticking in self.tickings {
            ticking.frame()
        }

        // Add every "new" ticking
        // This is in case new tickings are added in one of the tickings `frame()`
        // call. As we don't want to mutate the list as we iterate over it, we need
        // to collect every "new" ticking in a temporary list and add them all here.
        self.tickings.append(contentsOf: self.newTickings)
        self.newTickings = []

        // Collect every finished ticking (= keep every ticking that's not finished)
        self.tickings = self.tickings.filter {
            if $0.finished {
                Logger.debug(debugTickings, "Collecting finished ticking")
                return false
            }

            return true
        }

        self.insideFrame = false
    }
}

/// A "ticking" is something that runs every frame until it's finished.
/// Examples are: animations, background tasks...
/// Can only be used on classes.
public protocol Ticking: AnyObject {
    /// Method called every frame to run the ticking.
    func frame()

    /// Must return `true` if the ticking is finished and should be collected.
    var finished: Bool { get }
}

/// Context shared instance.
var contextSharedInstance: Context!

/// Allows to get the running app "context" instance.
public func getContext() -> Context {
    return contextSharedInstance
}

extension Application {
    /// Main entry point of an application. Use the `@main` attribute to
    /// use it in your executable target. Calling it manually is not supported.
    public static func main() throws {
        let app = try self.init()
        app.run()
    }
}

/// Runs everything in the main queue.
func drainMainQueue() {
    // XXX: Dispatch does not expose a way to drain the main queue
    // without parking the main thread, so we need to use obscure
    // CoreFoundation / Cocoa functions.
    // See https://github.com/apple/swift-corelibs-libdispatch/blob/macosforge/trac/ticket/38.md
    _dispatch_main_queue_callback_4CF(nil)
}
