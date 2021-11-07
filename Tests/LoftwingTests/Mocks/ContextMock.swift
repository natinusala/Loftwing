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

import Impostor

@testable import Skia
@testable import Loftwing

class WindowMock: Mock<Window>, Window {
    let canvas: Canvas? = nil
    let width: Float = 1280
    let height: Float = 720

    let colorSpace: OpaquePointer? = nil
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
    let window: Window

    let colorSpace: OpaquePointer? = nil
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
        return true
    }

    func backendTextureDelete(_ texture: OpaquePointer?) {}
}

/// Creates a fake context for the duration of the given test
/// then executes it.
func withContext(graphicsAPI: GraphicsAPI, test: () throws -> ()) throws {
    let context = ContextMock(graphicsAPI: graphicsAPI)

    contextSharedInstance = context
    skia = SkiaMock()

    try test()

    contextSharedInstance = nil
    skia = RealSkiaFunctions()
}
