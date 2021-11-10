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

class ActivitySpec: QuickSpec {
    override func spec() {
        describe("a content activity") {
            context("when initializing") {
                it("calls onCreate") {
                    let activity = ContentActivityMock()

                    activity.mock.expectWithInstance(activity) { a in
                        a.onCreate()
                    }
                }
            }

            context("every frame") {
                it("draws its content") {
                    let activity = ContentActivityMock()
                    let canvas = CanvasMock()

                    activity.frame(canvas: canvas)

                    activity.viewMock.mock.expectWithInstance(activity.viewMock) { v in
                        v.frame(canvas: canvas)
                    }
                }
            }

            context("when resized") {
                it("resizes every view") {
                    let activity = ContentActivityMock()

                    activity.resizeToFit(width: 1920, height: 1080)

                    activity.viewMock.mock.expectWithInstance(activity.viewMock) { v in
                        v.width(1920.dip)
                        v.height(1080.dip)
                    }
                }
            }
        }
    }
}
