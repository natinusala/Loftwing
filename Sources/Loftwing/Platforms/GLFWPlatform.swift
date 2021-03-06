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
import Glad
import Skia
import CLoftwing

enum GLFWError: Error {
    case initFailed
    case noPrimaryMonitor
    case noVideoMode
    case cannotCreateWindow
}

/// Set to `true` to enable sRGB color space.
/// TODO: make it an app setting instead of an hardcoded flag, move somewhere else (not GLFW specific)
let enableSRGB = false

/// GLFW as a platform, handling window and inputs.
class GLFWPlatform: Platform {
    let glfwWindow: GLFWWindow

    var window: Window? {
        return self.glfwWindow
    }

    required init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String,
        resetContext: Bool
    ) throws {
        // Set error callback
        glfwSetErrorCallback {code, error in
            Logger.error("GLFW error \(code): \(error.str ?? "unknown")")
        }

        // Init GLFW
        if glfwInit() != GLFW_TRUE {
            throw GLFWError.initFailed
        }

        // Create the initial window
        self.glfwWindow = try GLFWWindow(
            initialWindowMode: windowMode,
            initialGraphicsAPI: graphicsAPI,
            initialTitle: title,
            resetContext: resetContext
        )
    }

    func poll() -> Bool {
        glfwPollEvents()
        return self.glfwWindow.shouldClose()
    }
}

/// A GLFW window.
class GLFWWindow: Window {
    let windowMode: WindowMode
    let graphicsAPI: GraphicsAPI
    let title: String

    let window: OpaquePointer? // GLFW window

    let canvas: Canvas // Skia canvas
    let skContext: OpaquePointer? // Skia context
    let colorSpace: OpaquePointer?

    let width: Float
    let height: Float

    let resetContext: Bool

    init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String,
        resetContext: Bool
    ) throws {
        self.windowMode = windowMode
        self.graphicsAPI = graphicsAPI
        self.title = title
        self.resetContext = resetContext

        // Setup hints
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3)
        glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE)
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
        if enableSRGB {
            glfwWindowHint(GLFW_SRGB_CAPABLE, GLFW_TRUE)
        }
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
                gladLoadGLLoaderFromGLFW()

                if debugRenderer {
                    glEnable(GLenum(GL_DEBUG_OUTPUT))
                    glDebugMessageCallback(
                        { _, type, id, severity, _, message, _ in
                            onGlDebugMessage(severity: severity, type: type,  id: id, message: message)
                        },
                        nil
                    )
                }
        }

        // Enable sRGB if requested
        if enableSRGB {
            switch self.graphicsAPI {
                case .gl:
                    glEnable(UInt32(GL_FRAMEBUFFER_SRGB))
            }
        }

        var finalWindowWidth: Int32 = 0
        var finalWindowHeight: Int32 = 0
        glfwGetWindowSize(window, &finalWindowWidth, &finalWindowHeight)

        self.width = Float(finalWindowWidth)
        self.height = Float(finalWindowHeight)

        // Initialize Skia
        var backendRenderTarget: OpaquePointer?

        switch self.graphicsAPI {
            case .gl:
                let interface = gr_glinterface_create_native_interface()
                self.skContext = gr_direct_context_make_gl(interface)

                var framebufferInfo = gr_gl_framebufferinfo_t(
                    fFBOID: 0,
                    fFormat: UInt32(enableSRGB ? GL_SRGB8_ALPHA8 : GL_RGBA8)
                )

                backendRenderTarget = gr_backendrendertarget_new_gl(
                    finalWindowWidth,
                    finalWindowHeight,
                    0,
                    0,
                    &framebufferInfo
                )
        }

        guard let context = self.skContext else {
            throw SkiaError.cannotInitSkiaContext
        }

        guard let target = backendRenderTarget else {
            throw SkiaError.cannotInitSkiaTarget
        }

        let colorSpace: OpaquePointer? = enableSRGB ? sk_colorspace_new_srgb() : nil
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

        switch self.graphicsAPI {
            case .gl:
                var majorVersion: GLint = 0
                var minorVersion: GLint = 0
                glGetIntegerv(GLenum(GL_MAJOR_VERSION), &majorVersion)
                glGetIntegerv(GLenum(GL_MINOR_VERSION), &minorVersion)

                // TODO: better opengl logs (bullet point list, add vendor)

                Logger.info("OpenGL version: \(majorVersion).\(minorVersion)")
                Logger.info("GLSL language version: \(String(cString: glGetString(GLenum(GL_SHADING_LANGUAGE_VERSION))!))")
        }

        // Finalize init
        glfwSwapInterval(1)

        guard let nativeCanvas = sk_surface_get_canvas(surface) else {
            throw SkiaError.cannotInitSkiaCanvas
        }

        self.canvas = SkiaCanvas(nativeCanvas: nativeCanvas)
    }

    func swapBuffers() {
        if self.resetContext {
            gr_direct_context_reset_context(self.skContext, kAll_GrBackendState)
        }

        gr_direct_context_flush(self.skContext)
        glfwSwapBuffers(self.window)
    }

    // TODO: glfwDestroyWindow + glfwTerminate, free colorspace

    func shouldClose() -> Bool {
        return glfwWindowShouldClose(self.window) == 1
    }

    func makeContextCurrent() {
        Logger.debug(debugGraphics, "Making window context current")
        glfwMakeContextCurrent(self.window)
    }

    func makeOffscreenContext() -> OpaquePointer? {
        // This is apparently how you have an off-screen context using GLFW,
        // you just create an invisible window.

        glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE)
        let ctx = glfwCreateWindow(640, 480, "", nil, self.window)
        glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE)

        return ctx
    }

    func makeOffscreenContextCurrent(_ ctx: OpaquePointer?) {
        Logger.debug(debugGraphics, "Making offscreen context current")
        glfwMakeContextCurrent(ctx)
    }
}

private func onGlDebugMessage(severity: GLenum, type: GLenum, id: GLuint, message: UnsafePointer<CChar>?) {
    if type == GLenum(GL_DEBUG_TYPE_ERROR) {
        fatalError()
    }
    Logger.debug(debugRenderer, "OpenGL \(severity) \(id): \(message.str ?? "unspecified")")
}
