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

import XCTest

import Impostor
import Skia

@testable import Loftwing

/// Creates a fake app for the duration of the given test
/// then executes it.
/// The executed test has the app mock in parameter, allowing you to use
/// expect functions on it.
func withApp(graphicsAPI: GraphicsAPI = .gl, test: (ApplicationMock) throws -> ()) throws {
    skia = SkiaMock()
    platformCreator = MockPlatformCreator()

    let mock = try ApplicationMock(
        graphicsAPI: graphicsAPI
    )

    // context already set by application constructor

    try test(mock)

    contextSharedInstance = nil
    skia = RealSkiaFunctions()
    platformCreator = RealPlatformCreator()
}

class ApplicationMock: Application {
    typealias Predicate = () -> Bool

    var runFor: UInt = 0
    var framesCount: UInt = 0
    var predicate: Predicate = { return false }
    var predicateFulfilled = false

    let _graphicsAPI: GraphicsAPI

    override var graphicsAPI: GraphicsAPI {
        return self._graphicsAPI
    }

    init(graphicsAPI: GraphicsAPI) throws {
        self._graphicsAPI = graphicsAPI

        try super.init()
    }

    required init() throws {
        fatalError("ApplicationMock.init() must not be called directly")
    }

    override func shouldExit() -> Bool {
        if self.predicate() {
            self.predicateFulfilled = true
            return true
        }

        return super.shouldExit() || self.framesCount >= self.runFor
    }

    override func frame() {
        self.framesCount += 1
        super.frame()
    }

    /// Runs the app, expecting the given predicate to become `true` eventually.
    /// If the predicate does not come `true` before the fake app exits, the
    /// test will fail.
    func expect(before timeout: UInt, predicate: @escaping Predicate) {
        self.framesCount = 0
        self.runFor = timeout
        self.predicate = predicate

        self.run()

        if !self.predicateFulfilled {
            XCTFail("Predicate did not come true after running the app for \(timeout) frames")
        }
    }
}

class PlatformMock: Mock<Platform>, Platform {
    required init(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle: String,
        resetContext: Bool
    ) throws {
        self.window = WindowMock(graphicsAPI: graphicsAPI)
    }

    let window: Window?

    func poll() -> Bool {
        record()
        return false
    }
}

class MockPlatformCreator: PlatformCreator {
    func createPlatform(
        initialWindowMode windowMode: WindowMode,
        initialGraphicsAPI graphicsAPI: GraphicsAPI,
        initialTitle title: String,
        resetContext: Bool
    ) throws -> Platform {
        return try PlatformMock(
            initialWindowMode: windowMode,
            initialGraphicsAPI: graphicsAPI,
            initialTitle: title,
            resetContext: resetContext
        )
    }
}

class WindowMock: Mock<Window>, Window {
    let canvas: Canvas = CanvasMock()
    let width: Float = 1280
    let height: Float = 720

    let colorSpace: OpaquePointer? = OpaquePointer(bitPattern: 1234)
    let skContext = OpaquePointer(bitPattern: 1234)

    let graphicsAPI: GraphicsAPI

    init(graphicsAPI: GraphicsAPI) {
        self.graphicsAPI = graphicsAPI
    }

    func reload() throws {
        record()
    }

    func swapBuffers() {
        record()
    }

    func makeContextCurrent() {
        record()
    }

    func makeOffscreenContext() -> OpaquePointer? {
        record()
        return nil
    }

    func makeOffscreenContextCurrent(_ ctx: OpaquePointer?) {
        record(args: [ctx])
    }
}

class ContextMock: Context {
    let runner = Runner()
    let window: Window?

    let colorSpace = OpaquePointer(bitPattern: 1234)
    let skContext = OpaquePointer(bitPattern: 1234)

    let graphicsAPI: GraphicsAPI

    init(graphicsAPI: GraphicsAPI) {
        self.graphicsAPI = graphicsAPI

        self.window = WindowMock(
            graphicsAPI: graphicsAPI
        )
    }
}

/// Mocked Skia functions.
class SkiaMock: Mock<SkiaFunctions>, SkiaFunctions {
    func imageNewFromTexture(
        _ context: OpaquePointer?,
        _ texture: OpaquePointer?,
        _ origin: gr_surfaceorigin_t,
        _ colorType: sk_colortype_t,
        _ alpha: sk_alphatype_t,
        _ colorSpace: OpaquePointer?,
        _ releaseProc: sk_image_texture_release_proc?,
        _ releaseContext: UnsafeMutableRawPointer?
    ) -> OpaquePointer? {
        record(args: [context, texture, origin, colorType, alpha, colorSpace, releaseProc, releaseContext])
        return OpaquePointer(bitPattern: 1234)
    }

    func backendTextureIsValid(_ texture: OpaquePointer?) -> Bool {
        record(args: [texture])
        return true
    }

    func backendTextureDelete(_ texture: OpaquePointer?) {
        record(args: [texture])
    }
}
