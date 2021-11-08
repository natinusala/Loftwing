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
                it("stretches the image") {
                    let source = ImageSourceMock()
                    let image = ImageMock(source: source)

                    image.width(500.dip)
                    image.height(250.dip)
                    image.scalingMode(.stretch)

                    image.layout()

                    expect(image.imageRect).to(equal(Rect(x: 0, y: 0, width: 500, height: 250)))
                }
            }

            describe("the measure func") {
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
