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
                    // Same res as image
                    (width: 800, height: 600, expected: Rect(x: 0, y: 0, width: 800, height: 600)),
                    // Same ratio as image
                    (width: 600, height: 450, expected: Rect(x: 0, y: 0, width: 800, height: 600)),
                    // Landscape upscale
                    (width: 600, height: 225, expected: Rect(x: 0, y: 150, width: 800, height: 300)),
                    // Portrait upscale
                    (width: 225, height: 600, expected: Rect(x: 287.5, y: 0, width: 225, height: 600)),
                ]
                fitParams.forEach { (width, height, expected) in
                    context("when fitting an image of size \(width)x\(height)") {
                        it("makes an imageRect of \(expected)") {
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
