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

import Yoga
@testable import Loftwing

class ImageSpec: QuickSpec {
    override func spec() {
        describe("an image") {
            context("when unowned source changes") {
                it("updates source") {
                    try withApp { app in
                        @Observable var source: ImageSource?

                        let image = Image(unownedSource: $source)

                        expect(image.source).to(beNil())

                        let mock = ImageSourceMock()
                        source = mock

                        app.expect(before: 5) { image.source === mock }
                    }
                }

                it("invalidates layout") {
                    try withApp { app in
                        @Observable var source: ImageSource?

                        let image = ImageMock(unownedSource: $source)

                        let mock = ImageSourceMock()
                        source = mock

                        app.expect(before: 5) {
                            image.mock.hasCallsWithInstance(image) { i in
                                i.invalidateLayout()
                            }
                        }
                    }
                }
            }

            context("when scaling mode changes") {
                it("invalidates layout") {
                    let image = ImageMock(source: ImageSourceMock())
                    image.scalingMode(.stretch)
                    image.mock.expectWithInstance(image) { i in
                        i.invalidateLayout()
                    }
                }
            }

            // TODO: test with portrait and square views too

            context("when laying out") {
                let stretchParams: [(width: Float, height: Float)] = [
                    (width: 0, height: 0),
                    (width: 500, height: 250),
                    (width: 800, height: 600),
                ]
                stretchParams.forEach { (width, height) in
                    context("when stretching an image of size \(width)x\(height)") {
                        it("stretches the image to \(width)x\(height)") {
                            let image = ImageMock(source: ImageSourceMock())

                            image.width(width.dip)
                            image.height(height.dip)
                            image.scalingMode(.stretch)

                            image.layout()

                            expect(image.imageRect).to(equal(Rect(x: 0, y: 0, width: width, height: height)))
                        }
                    }
                }

                let fitParams: [(width: Float, height: Float, expected: Rect)] = [
                    // Square upscale
                    (width: 200, height: 200, expected: Rect(x: 100, y: 0, width: 600, height: 600)),
                    // Same res as view
                    (width: 800, height: 600, expected: Rect(x: 0, y: 0, width: 800, height: 600)),
                    // Same ratio as view
                    (width: 600, height: 450, expected: Rect(x: 0, y: 0, width: 800, height: 600)),
                    // Landscape upscale
                    (width: 600, height: 225, expected: Rect(x: 0, y: 150, width: 800, height: 300)),
                    // Portrait upscale
                    (width: 225, height: 600, expected: Rect(x: 287.5, y: 0, width: 225, height: 600)),
                ]
                fitParams.forEach { (width, height, expected) in
                    context("when fitting an image of size \(width)x\(height)") {
                        it("fits the image in \(expected)") {
                            let source = ImageSourceMock(width: width, height: height)
                            let image = ImageMock(source: source)

                            image.width(800.dip)
                            image.height(600.dip)
                            image.scalingMode(.fit)

                            image.layout()

                            expect(image.imageRect).to(equal(expected))
                        }
                    }
                }

                let centerParams: [(width: Float, height: Float, expected: Rect)] = [
                    // Same dimensions as view
                    (width: 800, height: 600, expected: Rect(x: 0, y: 0, width: 800, height: 600)),
                    // Square
                    (width: 200, height: 200, expected: Rect(x: 300, y: 200, width: 200, height: 200)),
                    // Same ratio as view
                    (width: 600, height: 450, expected: Rect(x: 100, y: 75, width: 600, height: 450)),
                    // Bigger image
                    (width: 1280, height: 720, expected: Rect(x: -240, y: -60, width: 1280, height: 720)),
                    // Landscape
                    (width: 600, height: 225, expected: Rect(x: 100, y: 187.5, width: 600, height: 225)),
                    // Portrait
                    (width: 225, height: 400, expected: Rect(x: 287.5, y: 100, width: 225, height: 400)),
                ]
                centerParams.forEach { (width, height, expected) in
                    context("when centering an image of \(width)x\(height)") {
                        it("centers the image in \(expected)") {
                            let source = ImageSourceMock(width: width, height: height)
                            let image = ImageMock(source: source)

                            image.width(800.dip)
                            image.height(600.dip)
                            image.scalingMode(.center)

                            image.layout()

                            expect(image.imageRect).to(equal(expected))
                        }
                    }
                }

                let integerParams: [(width: Float, height: Float, scaleFactor: Int?, expected: Rect)] = [
                    // Scale as much as possible - same dimensions as view
                    (width: 800, height: 600, scaleFactor: nil, expected: Rect(x: 0, y: 0, width: 800, height: 600)),
                    // Scale as much as possible - square
                    (width: 200, height: 200, scaleFactor: nil, expected: Rect(x: 100, y: 0, width: 600, height: 600)),
                    // Scale as much as possible - landscape
                    (width: 150, height: 75, scaleFactor: nil, expected: Rect(x: 25, y: 112.5, width: 750, height: 375)),
                    // Scale as much as possible - portrait
                    (width: 75, height: 150, scaleFactor: nil, expected: Rect(x: 250, y: 0, width: 300, height: 600)),

                    // 1:1 scaling - same dimensions as view
                    (width: 800, height: 600, scaleFactor: 1, expected: Rect(x: 0, y: 0, width: 800, height: 600)),
                    // 1:1 scaling - square
                    (width: 200, height: 200, scaleFactor: 1, expected: Rect(x: 300, y: 200, width: 200, height: 200)),
                    // 1:1 scaling - landscape
                    (width: 150, height: 75, scaleFactor: 1, expected: Rect(x: 325, y: 262.5, width: 150, height: 75)),
                    // 1:1 scaling - portrait
                    (width: 75, height: 150, scaleFactor: 1, expected: Rect(x: 362.5, y: 225, width: 75, height: 150)),

                    // Fixed scaling - same dimensions as view
                    (width: 800, height: 600, scaleFactor: 3, expected: Rect(x: -800, y: -600, width: 2400, height: 1800)),
                    // Fixed scaling - square
                    (width: 200, height: 200, scaleFactor: 2, expected: Rect(x: 200, y: 100, width: 400, height: 400)),
                    // Fixed scaling - landscape
                    (width: 150, height: 75, scaleFactor: 2, expected: Rect(x: 250, y: 225, width: 300, height: 150)),
                    // Fixed scaling - portrait
                    (width: 75, height: 150, scaleFactor: 2, expected: Rect(x: 325, y: 150, width: 150, height: 300)),

                    // Larger scaling - same dimensions as view
                    (width: 800, height: 600, scaleFactor: 10, expected: Rect(x: -3600, y: -2700, width: 8000, height: 6000)),
                    // Larger scaling - square
                    (width: 450, height: 450, scaleFactor: 10, expected: Rect(x: -1850, y: -1950, width: 4500, height: 4500)),
                    // Larger scaling - landscape
                    (width: 1920, height: 1080, scaleFactor: 10, expected: Rect(x: -9200, y: -5100, width: 19200, height: 10800)),
                    // Larger scaling - portrait
                    (width: 256, height: 384, scaleFactor: 10, expected: Rect(x: -880, y: -1620, width: 2560, height: 3840)),
                ]
                integerParams.forEach { (width, height, scaleFactor, expected) in
                    context("when scaling by \(String(describing: scaleFactor)) an image of \(width)x\(height)") {
                        it("scales the image in \(expected)") {
                            let source = ImageSourceMock(width: width, height: height)
                            let image = ImageMock(source: source)

                            image.width(800.dip)
                            image.height(600.dip)
                            image.scalingMode(.integer(scaleFactor))

                            image.layout()

                            expect(image.imageRect).to(equal(expected))
                        }
                    }
                }
            }

            context("when there is no source") {
                it("doesn't draw anything") {
                    let image = Image()
                    let canvas = CanvasMock()

                    image.draw(canvas: canvas)

                    canvas.expectNotCalled(funcName: "drawImage(_:destRect:paint:)")
                }
            }

            context("when there is a source") {
                it("draws the source") {
                    let source = ImageSourceMock()
                    let image = Image(source: source)
                    let canvas = CanvasMock()

                    image.draw(canvas: canvas)

                    canvas.expect { c in
                        c.drawImage(source, destRect: image.imageRect, paint:image.paint)
                    }
                }
            }

            describe("its measure func") {
                context("when resizing is disabled") {
                    it("returns no size") {
                        let image = ImageMock(source: ImageSourceMock(), resizeViewToFitImage: false)
                        expect(image.measureFunc(YGUndefined, .undefined, YGUndefined, .undefined)).to(equal((nil, nil)))
                    }
                }
            }
        }
    }
}
