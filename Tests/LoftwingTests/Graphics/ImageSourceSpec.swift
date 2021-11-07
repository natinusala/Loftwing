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

import Quick
import Nimble

@testable import Loftwing

class ImageSourceSpec: QuickSpec {
    override func spec() {
        describe("a GPU texture image source") {
            it("creates a Skia image") {
                try withApp(graphicsAPI: .gl) { _ in
                    let texture = try GPUTextureMock(width: 800, height: 600, pixelFormat: .rgb565)

                    expect(texture.skImage).toNot(beNil())
                }
            }

            context("when the draw rect is unspecified") {
                it("has a draw rect with full image dimensions") {
                    try withApp(graphicsAPI: .gl) { _ in
                        let texture = try GPUTextureMock(width: 800, height: 600, pixelFormat: .rgb565)

                        expect(texture.drawRect).to(equal(Rect(x: 0, y: 0, width: 800, height: 600)))
                        expect(texture.width).to(equal(800))
                        expect(texture.height).to(equal(600))
                    }
                }
            }

            context("when the draw rect is specified") {
                it("has a draw rect") {
                    try withApp(graphicsAPI: .gl) { _ in
                        let texture = try GPUTextureMock(
                            width: 800,
                            height: 600,
                            pixelFormat: .rgb565,
                            drawRect: Rect(x: 100, y: 100, width: 200, height: 200)
                        )

                        expect(texture.drawRect).to(equal(Rect(x: 100, y: 100, width: 200, height: 200)))
                    }
                }

                it("has draw rect dimensions") {
                    try withApp(graphicsAPI: .gl) { _ in
                        let texture = try GPUTextureMock(
                            width: 800,
                            height: 600,
                            pixelFormat: .rgb565,
                            drawRect: Rect(x: 100, y: 100, width: 200, height: 200)
                        )

                        expect(texture.width).to(equal(200))
                        expect(texture.height).to(equal(200))
                    }
                }
            }
        }
    }
}
