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

/// Application protocol. Implement these methods in your
/// LoftwingApplication subclass.
public protocol Application {
    /// Application initial window mode.
    var initialWindowMode: WindowMode { get }

    /// Application initial graphics context. Use nil to autodetect and pick the
    /// first one that works.
    var initialGraphicsAPI: GraphicsAPI? { get }

    /// The first activity started by the application.
    var mainActivity: Activity { get }

    /// Application window title.
    var title: String { get }
}

public extension Application {
    /// Runs the application until closed, either by the user
    /// or through exit().
    func main() throws {
        try InternalApplication(with: self).main()
    }
}

/// A Loftwing application.
class InternalApplication {
    let window: Window

    /// Creates an application with given window mode and graphics context.
    init(
        with configuration: Application
    ) throws {
        // Create platform handle, get every driver
        let platform = try createPlatform(
            initialWindowMode: configuration.initialWindowMode,
            initialGraphicsAPI: try configuration.initialGraphicsAPI ?? GraphicsAPI.findFirstAvailable(),
            initialTitle: configuration.title
        )

        // Create window
        self.window = platform.window
    }

    /// Runs the application until closed, either by the user
    /// or through exit().
    public func main() throws {
        // Load window
        do {
            try self.window.reload()
        } catch {
            Logger.error("Could not create window: \(error)")
            throw error
        }
    }

    /// Requests the application to be exited. Returns when the app is fully
    /// exited and the window is closed.
    public func exit() async {
        // TODO: do it
    }
}
