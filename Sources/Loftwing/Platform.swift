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

/// Selects and creates the platform to use for an application.
func createPlatform(
    initialWindowMode windowMode: WindowMode,
    initialGraphicsAPI graphicsAPI: GraphicsAPI,
    initialTitle title: String
) throws -> Platform {
    // TODO: only return GLFW if it's actually supported
    return try GLFWPlatform(
        initialWindowMode: windowMode,
        initialGraphicsAPI: graphicsAPI,
        initialTitle: title
    )
}

/// Protocol representing a platform a Loftwing app can run on.
/// Each platform can implement one or more graphics context.
/// Graphics context hotswapping is supported but not platform hotswapping,
/// for obvious reasons.
protocol Platform {
    init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle: String
    ) throws

    /// Current window handle.
    var window: Window { get }

    /// Called before every frame begins to poll events and prepare the frame.
    /// Must return true if the application should exit.
    func poll() -> Bool
}

/// The window mode of an application.
public enum WindowMode {
    /// Windowed window with given initial width and height.
    case windowed(Float, Float)
    /// Fullscreen borderless window.
    case borderlessWindow
    /// Fullscreen application.
    case fullscreen
}

/// Window creation errors.
public enum WindowCreationError: Error {
    case noGraphicsAPIAvailable
    case noSkiaCanvas
}

/// The graphics API / renderer of an application.
public enum GraphicsAPI {
    /// OpenGL.
    case OpenGL

    /// Selects the first available graphics API, or throws if none is
    /// available.
    public static func findFirstAvailable() throws -> GraphicsAPI {
        // TODO: only return OpenGL if it's actually available
        return .OpenGL
    }
}

/// Represents an application window.
protocol Window {
    /// Skia canvas pointer.
    var canvas: OpaquePointer? { get }

    /// Loads or reloads the window. If called for the first time, will create
    /// and open a new window. If called when a window already exists, the existing
    /// window will be closed, all graphics resources will be released and a new window
    /// will be created in its place (using the same configuration).
    func reload() throws

    /// Called at the end of every frame
    func swapBuffers()
}
