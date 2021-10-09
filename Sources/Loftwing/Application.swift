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

/// A Loftwing application. As the library is designed to make fullscreen,
/// single window / kiosk apps, running multiple apps per executable target is not
/// supported.
///
/// To use, create a struct that conforms to that protocol and add the `@main`
/// attribute.
public protocol Application {
    init()

    /// Application title.
    var title: String { get }

    /// Initial window mode.
    var initialWindowMode: WindowMode { get }

    /// Initial graphics context. Use nil to autodetect and pick the
    /// first one that works.
    var initialGraphicsAPI: GraphicsAPI? { get }

    /// The first activity started by the application.
    var mainActivity: Activity { get }
}

extension Application {
    /// Main entry point of an application. Use the `@main` attribute to
    /// use it in your executable target. Calling it manually is not supported.
    public static func main() async throws {
        try await InternalApplication(with: self.init()).main()
    }
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
public protocol Ticking {
    /// Method called every frame to run the ticking.
    func frame()

    /// Must return `true` if the ticking is finished and should be collected.
    var finished: Bool { get }
}

/// The "context" of an app can be retreived from anywhere using `getContext().
/// Contains app state, metadata and useful "managers".
@MainActor
public protocol Context {
    var runner: Runner { get }
}

/// Context shared instance.
private var contextSharedInstance: Context!

/// Allows to get the running app "context" instance.
public func getContext() -> Context {
    return contextSharedInstance
}

/// Internal application singleton.
@MainActor
open class InternalApplication: Context {
    let configuration: Application

    var window: Window
    var platform: Platform

    var shouldStop = false
    var stopCallback: (() -> ())? = nil

    let activitiesStackLayer = ActivitiesStackLayer()
    var layers: [Layer] = []

    let clearPaint = Paint(color: Color.black)

    public var runner = Runner()

    /// Creates an application.
    init(with configuration: Application) throws {
        self.configuration = configuration

        // Initialize platform
        self.platform = try createPlatform(
            initialWindowMode: configuration.initialWindowMode,
            initialGraphicsAPI: try configuration.initialGraphicsAPI ?? GraphicsAPI.findFirstAvailable(),
            initialTitle: configuration.title
        )

        // Create window
        self.window = self.platform.window

        // Create layers
        self.layers = [
            self.activitiesStackLayer
            // TODO: OverlayLayer, which is a subclass of ViewLayer
        ]

        // Register ourself as the running context
        contextSharedInstance = self
    }

    /// Runs the application until closed, either by the user
    /// or through exit().
    public func main() async throws {
        // Load window
        do {
            try self.window.reload()

            // Ensure the window has a Skia canvas
            if self.window.canvas == nil {
                throw WindowCreationError.noSkiaCanvas
            }
        } catch {
            Logger.error("Could not create window: \(error)")
            throw error
        }

        // Push main activity
        await self.activitiesStackLayer.push(activity: self.configuration.mainActivity)

        // Resize every layer
        for layer in self.layers {
            layer.resizeToFit(width: window.width, height: window.height)
        }

        // Main loop
        while(true) {
            // Poll platform, see if we should exit
            // TODO: handle ctrlc to gracefully exit
            if self.platform.poll() || self.shouldStop {
                // Exit
                Logger.info("Exiting...")

                await self.onExit()

                // Call stop callback
                if let cb = stopCallback {
                    cb()
                }

                // Break the loop to exit
                break
            }

            // Clear in black
            self.window.canvas!.drawPaint(self.clearPaint)

            // Draw layers
            for layer in self.layers {
                // TODO: saveLayer and restore?
                layer.frame(canvas: self.window.canvas!)
            }

            // Swap buffers
            self.window.swapBuffers()

            // Run runner for one frame
            self.runner.frame()

            // Sleep between frames
            // TODO: sleep better with dynamic rate control
            await Task.sleep(16666666)
        }
    }

    /// Requests the application to be exited. Returns when the app is fully
    /// exited and the window is closed.
    public func exit() async {
        await withUnsafeContinuation { continuation in
            self.exit {
                continuation.resume()
            }
        }
    }

    /// Requests the application to be exited. Runs the given callback when the app is fully
    /// exited and the window is closed.
    public func exit(callback: @escaping () -> ()) {
        self.stopCallback = callback
        self.shouldStop = true
    }

    /// Called when the app exits.
    open func onExit() async {
        // Nothing by default
    }
}
