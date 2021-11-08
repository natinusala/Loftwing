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

/// Errors that can happen when Skia is initialized.
public enum SkiaError: Error {
    case cannotInitSkiaContext
    case cannotInitSkiaTarget
    case cannotInitSkiaSurface
    case cannotInitSkiaCanvas
}

protocol PlatformCreator {
    /// Selects and creates the platform to use for an application.
    func createPlatform(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String,
        resetContext: Bool
    ) throws -> Platform
}

class RealPlatformCreator: PlatformCreator {
    func createPlatform(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String,
        resetContext: Bool
    ) throws -> Platform {
        // TODO: only return GLFW if it's actually supported
        return try GLFWPlatform(
            initialWindowMode: windowMode,
            initialGraphicsAPI: graphicsAPI,
            initialTitle: title,
            resetContext: resetContext
        )
    }
}

/// Can be called to create the currently running platform handle.
/// Test targets override this mock of their own.
var platformCreator: PlatformCreator = RealPlatformCreator()

/// Protocol representing a platform a Loftwing app can run on.
/// Each platform can implement one or more graphics context.
/// Graphics context hotswapping is supported but not platform hotswapping,
/// for obvious reasons.
protocol Platform {
    init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle: String,
        resetContext: Bool
    ) throws

    /// Current window handle.
    var window: Window? { get }

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
    case gl

    /// Selects the first available graphics API, or fatal errors if none is
    /// available.
    public static func findFirstAvailable() -> GraphicsAPI {
        // TODO: only return OpenGL if it's actually available
        return .gl
    }
}

/// Represents an application window.
public protocol Window {
    /// Graphics canvas.
    var canvas: Canvas { get }

    /// Current window width.
    var width: Float { get }

    /// Current window height.
    var height: Float { get }

    /// Called at the end of every frame
    func swapBuffers()

    /// Skia color space.
    var colorSpace: OpaquePointer? { get }

    /// Graphics API.
    var graphicsAPI: GraphicsAPI { get }

    /// Skia context.
    var skContext: OpaquePointer? { get }

    /// Makes the window context current.
    func makeContextCurrent()

    /// Creates a new offscreen graphics API context.
    func makeOffscreenContext() -> OpaquePointer?

    /// Makes an offscreen context current.
    func makeOffscreenContextCurrent(_ ctx: OpaquePointer?)
}
