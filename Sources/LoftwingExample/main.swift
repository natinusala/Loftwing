import Foundation

import GLFW
import NanoVG

if glfwInit() != GLFW_TRUE {
    print("Failed to init glfw")
    abort()
}

let window = glfwCreateWindow(800, 600, "NVG test", nil, nil)

if window == nil {
    print("Failed to create window")
    glfwTerminate()
    abort()
}

glfwMakeContextCurrent(window)

guard let vg = NVGContext(flags: NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG) else {
    print("Failed to init NVG")
    abort()
}

glfwSwapInterval(0)

while glfwWindowShouldClose(window) == 0 {
    var winWidth: Int32 = 0
    var winHeight: Int32 = 0
    glfwGetWindowSize(window, &winWidth, &winHeight)

    var fbWidth: Int32 = 0
    var fbHeight: Int32 = 0
    glfwGetFramebufferSize(window, &fbWidth, &fbHeight)

    let pxRatio = Float(fbWidth) / Float(winWidth);

    glViewport(0, 0, fbWidth, fbHeight)

    glClearColor(0,0,0,0)

    glClear(UInt32(GL_COLOR_BUFFER_BIT) | UInt32(GL_DEPTH_BUFFER_BIT) | UInt32(GL_STENCIL_BUFFER_BIT))

    let frame = vg.beginFrame(
        windowWidth: Float(winWidth),
        windowHeight: Float(winHeight),
        devicePixelRatio: pxRatio
    )

    frame.beginPath()
        .rect(x: 0, y: 0, width: 100, height: 100)
        .fillColor(nvgRGBA(28, 30, 34, 192))
        .fill()

    frame.end()

    glfwSwapBuffers(window)
    glfwPollEvents()
}
