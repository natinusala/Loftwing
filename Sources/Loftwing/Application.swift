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

/// A Loftwing application.
open class Application {
    /// Application initial window mode.
    open var initialWindowMode: WindowMode {
        WindowMode.borderlessWindow
    }

    /// Application initial graphics context. Use nil to autodetect and pick the
    /// first one that works.
    open var initialGraphicsAPI: GraphicsAPI? {
        nil
    }

    /// The first activity started by the application.
    open var mainActivity: Activity? {
        nil
    }

    /// Application window title.
    open var title: String {
        "Loftwing App"
    }

    var window: Window!
    var platform: Platform!

    var shouldStop = false
    var stopCallback: (() -> ())? = nil

    var activitiesStack: [Activity] = []

    /// Creates an application.
    public init() throws {
        // Initialize platform
        self.platform = try createPlatform(
            initialWindowMode: self.initialWindowMode,
            initialGraphicsAPI: try self.initialGraphicsAPI ?? GraphicsAPI.findFirstAvailable(),
            initialTitle: self.title
        )

        // Create window
        self.window = self.platform.window

        // Push main activity
        if let mainActivity = self.mainActivity {
            self.activitiesStack = [mainActivity]
        }
    }

    /// Runs the application until closed, either by the user
    /// or through exit().
    public func main() throws {
        // Create window
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

        // Main loop
        while(true) {
            // Poll platform, see if we should exit
            if self.platform.poll() || self.shouldStop {
                // Exit
                Logger.info("Exiting...")

                // Call stop callback
                if let cb = stopCallback {
                    cb()
                }

                // TODO: Deinit stuff

                // Break the loop to exit
                break
            }

            // Draw activities
            // TODO: do it better (see borealis)
            for activity in activitiesStack {
                activity.frame()
            }

            // Finally swap buffers
            self.window.swapBuffers()
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
        // TODO: call onExit event when the event loop is made - turn exit into an event?
        self.stopCallback = callback
        self.shouldStop = true
    }
}
