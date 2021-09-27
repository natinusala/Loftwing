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

/// The window mode of an application.
public enum WindowMode {
    /// Windowed window with given initial width and height.
    case windowed(Float, Float)
    /// Fullscreen windowed window.
    case fullscreen_windowed
    /// Fullscreen application.
    case fullscreen
}

/// Window creation errors.
public enum WindowCreationError: Error {
    case noGraphicsContextAvailable
}

/// The graphics context / renderer of an application.
public enum GraphicsContext {
    /// OpenGL context.
    case OpenGL

    /// Selects the first available graphics context, or nil if none is
    /// available.
    public static func findFirstAvailable() throws -> GraphicsContext {
        // TODO: only return OpenGL if it's actually available
        return .OpenGL
    }
}

/// Represents an application window.
class Window {
    let mode: WindowMode
    let graphicsContext: GraphicsContext

    init(
        initialMode mode: WindowMode,
        initialGraphicsContext ctx: GraphicsContext?
    ) throws {
        self.mode = mode
        self.graphicsContext = try ctx ?? GraphicsContext.findFirstAvailable()
    }
}
