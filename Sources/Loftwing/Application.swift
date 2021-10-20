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
open class Application {
    let creationEvent = Event<Void>()

    required public init() async {
        // Observe our own creation event
        self.creationEvent.observe(owner: self) {
            await self.onCreate()
        }
    }

    /// Application title.
    open var title: String {
        "Loftwing App"
    }

    /// Initial window mode.
    open var initialWindowMode: WindowMode {
        .borderlessWindow
    }

    /// Initial graphics context. Use nil to autodetect and pick the
    /// first one that works.
    open var initialGraphicsAPI: GraphicsAPI? {
        nil
    }

    /// The first activity started by the application.
    open var mainActivity: Activity {
        Activity()
    }

    /// The layer containing the "content" of your app: a game, a video player...
    /// It will be placed under the activities layer.
    open var contentLayer: Layer? {
        nil
    }

    /// Method called when the application is created and ready to run.
    open func onCreate() async {
        // Nothing by default
    }
}

/// The "context" of an app can be retreived from anywhere using `getContext().
/// Contains app state, metadata and useful "managers".
public protocol Context {
    var runner: Runner { get }
    var colorSpace: OpaquePointer? { get }
    var graphicsAPI: GraphicsAPI { get }
    var skiaContext: OpaquePointer? { get }
}

/// Internal application singleton.
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
    public var colorSpace: OpaquePointer?
    public var graphicsAPI: GraphicsAPI
    public var skiaContext: OpaquePointer?

    /// Creates an application.
    init(with configuration: Application) async throws {
        self.configuration = configuration

        // Initialize platform
        self.platform = try await createPlatform(
            initialWindowMode: configuration.initialWindowMode,
            initialGraphicsAPI: try configuration.initialGraphicsAPI ?? GraphicsAPI.findFirstAvailable(),
            initialTitle: configuration.title
        )

        // Create window
        self.window = self.platform.window

        // Set context properties
        self.graphicsAPI = await window.graphicsAPI

        // Create layers
        self.layers = [
            self.activitiesStackLayer
            // TODO: OverlayLayer, which is a subclass of ViewLayer
        ]

        if let contentLayer = configuration.contentLayer {
            self.layers.insert(contentLayer, at: 0)
        }

        // Register ourself as the running context
        contextSharedInstance = self
    }

    /// Runs the application until closed, either by the user
    /// or through exit().
    @MainActor
    public func main() async throws {
        // Load window
        do {
            try self.window.reload()

            //Refresh context
            self.skiaContext = window.skiaContext
            self.colorSpace = window.colorSpace

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

        // Fire the creation event when everything is ready
        self.configuration.creationEvent.fire()

        // Main loop
        while(true) {
            // Poll platform, see if we should exit
            // TODO: handle ctrlc to gracefully exit
            if await self.platform.poll() || self.shouldStop {
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
                await layer.frame(canvas: self.window.canvas!)
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
    @MainActor
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
    @MainActor
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
    public static func main() async throws {
        try await InternalApplication(with: self.init()).main()
    }
}
