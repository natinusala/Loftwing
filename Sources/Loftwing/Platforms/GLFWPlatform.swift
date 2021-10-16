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

import GLFW
import Skia

enum GLFWError: Error {
    case initFailed
    case noPrimaryMonitor
    case noVideoMode
    case cannotCreateWindow
}

/// GLFW as a platform, handling window and inputs.
class GLFWPlatform: Platform {
    let glfwWindow: GLFWWindow

    var window: Window {
        return self.glfwWindow
    }

    required init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String
    ) async throws {
        // Set error callback
        glfwSetErrorCallback {code, error in
            if let errorString = error {
                Logger.error("GLFW error \(code): \(errorString)")
            }
            else {
                Logger.error("GLFW error \(code): unknown")
            }
        }

        // Init GLFW
        if glfwInit() != GLFW_TRUE {
            throw GLFWError.initFailed
        }

        // Create the window
        self.glfwWindow = try await GLFWWindow(
            initialWindowMode: windowMode,
            initialGraphicsAPI: graphicsAPI,
            initialTitle: title
        )
    }

    func poll() async -> Bool {
        glfwPollEvents()
        return await self.glfwWindow.shouldClose()
    }
}

/// A GLFW window.
@MainActor
class GLFWWindow: Window {
    let windowMode: WindowMode
    let graphicsAPI: GraphicsAPI
    let title: String

    var window: OpaquePointer? = nil // GLFW window

    var canvas: Canvas? = nil // Skia canvas
    var skiaContext: OpaquePointer? = nil // Skia context
    var colorSpace: OpaquePointer? = nil

    var width: Float = 0
    var height: Float = 0

    init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String
    ) throws {
        self.windowMode = windowMode
        self.graphicsAPI = graphicsAPI
        self.title = title
    }

    func swapBuffers() {
        gr_direct_context_flush(self.skiaContext)
        glfwSwapBuffers(self.window)
    }

    func reload() throws {
        // TODO: teardown existing window + Skia instead of aborting
        if self.window != nil {
            Logger.error("Reloading not implemented on GLFW")
            fatalError()
        }

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

        if self.window == nil {
            throw GLFWError.cannotCreateWindow
        }

        Logger.info("Created \(self.windowMode) window")

        // Initialize graphics API
        glfwMakeContextCurrent(window)

        switch self.graphicsAPI {
            case .gl:
                glEnable(UInt32(GL_FRAMEBUFFER_SRGB))
        }

        var finalWindowWidth: Int32 = 0
        var finalWindowHeight: Int32 = 0
        glfwGetWindowSize(window, &finalWindowWidth, &finalWindowHeight)

        self.width = Float(finalWindowWidth)
        self.height = Float(finalWindowHeight)

        // Initialize Skia
        var backendRenderTarget: OpaquePointer? = nil

        switch self.graphicsAPI {
            case .gl:
                let interface = gr_glinterface_create_native_interface()
                self.skiaContext = gr_direct_context_make_gl(interface)

                var framebufferInfo = gr_gl_framebufferinfo_t(
                    fFBOID: 0,
                    fFormat: UInt32(GL_SRGB8_ALPHA8)
                )

                backendRenderTarget = gr_backendrendertarget_new_gl(
                    finalWindowWidth,
                    finalWindowHeight,
                    0,
                    0,
                    &framebufferInfo
                )
        }

        guard let context = self.skiaContext else {
            throw SkiaError.cannotInitSkiaContext
        }

        guard let target = backendRenderTarget else {
            throw SkiaError.cannotInitSkiaTarget
        }

        let colorSpace = sk_colorspace_new_srgb()
        self.colorSpace = colorSpace

        let surface = sk_surface_new_backend_render_target(
            context,
            target,
            BOTTOM_LEFT_GR_SURFACE_ORIGIN,
            RGBA_8888_SK_COLORTYPE,
            colorSpace,
            nil
        )

        if surface == nil {
            throw SkiaError.cannotInitSkiaSurface
        }

        Logger.info("Created \(self.graphicsAPI) Skia context")

        // Finalize init
        glfwSwapInterval(1)

        guard let nativeCanvas = sk_surface_get_canvas(surface) else {
            throw SkiaError.cannotInitSkiaCanvas
        }

        self.canvas = SkiaCanvas(nativeCanvas: nativeCanvas)
    }

    // TODO: glfwDestroyWindow + glfwTerminate, free colorspace

    func shouldClose() -> Bool {
        return glfwWindowShouldClose(self.window) == 1
    }
}
