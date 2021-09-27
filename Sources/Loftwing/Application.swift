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
    init()

    /// Application initial window mode.
    var initialWindowMode: WindowMode { get }

    /// Application initial graphics context. Use nil to autodetect and pick the
    /// first one that works.
    var initialGraphicsContext: GraphicsContext? { get }

    /// The first activity started by the application.
    var mainActivity: Activity { get }
}

public extension Application {
    /// Runs the application until closed, either by the user
    /// or through exit().
    static func main() throws {
        try InternalApplication(with: self.init()).main()
    }
}

/// A Loftwing application.
class InternalApplication {
    let window: Window
    let configuration: Application

    /// Creates an application with given window mode and graphics context.
    init(
        with configuration: Application
    ) throws {
        self.configuration = configuration
        self.window = try Window(
            initialMode: configuration.initialWindowMode,
            initialGraphicsContext: configuration.initialGraphicsContext
        )
    }

    /// Runs the application until closed, either by the user
    /// or through exit().
    public func main() {

    }

    /// Requests the application to be exited.
    public func exit() async {
        // TODO: do it
    }
}
