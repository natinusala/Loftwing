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

import GLFW

enum GLFWError: Error {
    case initFailed
    case noPrimaryMonitor
    case noVideoMode
}

/// GLFW as a platform, handling window and inputs.
class GLFWPlatform: Platform {
    let window: Window

    required init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String
    ) throws {
        // Init GLFW
        if glfwInit() != GLFW_TRUE {
            throw GLFWError.initFailed
        }

        // Create the window
        self.window = try GLFWWindow(
            initialWindowMode: windowMode,
            initialGraphicsAPI: graphicsAPI,
            initialTitle: title
        )
    }
}

/// A GLFW window.
class GLFWWindow: Window {
    let windowMode: WindowMode
    let graphicsAPI: GraphicsAPI
    let title: String

    var window: OpaquePointer? = nil

    init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String
    ) throws {
        self.windowMode = windowMode
        self.graphicsAPI = graphicsAPI
        self.title = title
    }

    func reload() throws {
        // TODO: teardown existing window instead
        if self.window != nil {
            Logger.error("Reloading not implemented on GLFW")
            abort()
        }

        // Log
        Logger.info("Creating window:")
        Logger.info("   - Graphics API: \(self.graphicsAPI)")
        Logger.info("   - Mode: \(self.windowMode)")

        // Setup hints
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2)
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE)
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
        glfwWindowHint(GLFW_SRGB_CAPABLE, GL_TRUE)
        glfwWindowHint(GLFW_STENCIL_BITS, 0)
        glfwWindowHint(GLFW_ALPHA_BITS, 0)
        glfwWindowHint(GLFW_DEPTH_BITS, 0)

        // Reset mode specific values
        glfwWindowHint(GLFW_RED_BITS, GLFW_DONT_CARE)
        glfwWindowHint(GLFW_GREEN_BITS, GLFW_DONT_CARE)
        glfwWindowHint(GLFW_BLUE_BITS, GLFW_DONT_CARE)
        glfwWindowHint(GLFW_REFRESH_RATE, GLFW_DONT_CARE)

        // Get monitor and mode
        let monitor = glfwGetPrimaryMonitor()

        if monitor == nil {
            throw GLFWError.noPrimaryMonitor
        }

        guard let mode = glfwGetVideoMode(monitor) else {
            throw GLFWError.noVideoMode
        }

        // Create the new window
        switch self.windowMode {
            // Windowed mode
            case let .windowed(width, height):
                self.window = glfwCreateWindow(
                    Int32(width),
                    Int32(height),
                    self.title,
                    nil,
                    nil
                )
            // Borderless mode
            case .borderlessWindow:
                glfwWindowHint(GLFW_RED_BITS, mode.pointee.redBits)
                glfwWindowHint(GLFW_GREEN_BITS, mode.pointee.greenBits)
                glfwWindowHint(GLFW_BLUE_BITS, mode.pointee.blueBits)
                glfwWindowHint(GLFW_REFRESH_RATE, mode.pointee.refreshRate)

                self.window = glfwCreateWindow(
                    mode.pointee.width,
                    mode.pointee.height,
                    self.title,
                    monitor,
                    nil
                )
            // Fullscreen mode
            case .fullscreen:
                self.window = glfwCreateWindow(
                    mode.pointee.width,
                    mode.pointee.height,
                    self.title,
                    monitor,
                    nil
                )
        }
    }
}
