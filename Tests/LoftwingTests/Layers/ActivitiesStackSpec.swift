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

class ActivitiesStackSpec: QuickSpec {
    override func spec() {
        describe("an activities stack") {
            var stack: ActivitiesStack!

            beforeEach {
                stack = ActivitiesStack()
            }

            it("contains activities") {
                expect(stack).to(beEmpty())

                let activities = [
                    ActivityMock(),
                    ActivityMock(),
                    ActivityMock(),
                ]

                for activity in activities {
                    stack.push(activity: activity)
                }

                for activity in activities {
                    expect(stack).to(containElementSatisfying { $0 === activity })
                }
            }

            it("contains 1 activity") {
                expect(stack).to(beEmpty())

                let activity = ActivityMock()

                stack.push(activity: activity)

                expect(stack).to(containElementSatisfying { $0 === activity })
            }

            it("contains no activities") {
                expect(stack).to(beEmpty())
            }
        }

        describe("an activities stack layer") {
            var layer: ActivitiesStackLayer!

            beforeEach {
                layer = ActivitiesStackLayer()
            }

            it("draws activities") {
                let activity = ActivityMock()
                let canvas = CanvasMock()

                layer.push(activity: activity)
                layer.frame(canvas: canvas)

                activity.expect { a in
                    a.frame(canvas: canvas)
                }
            }

            it("resizes activities") {
                let activity = ActivityMock()

                layer.push(activity: activity)
                layer.resizeToFit(width: 800, height: 600)

                activity.expect { a in
                    a.resizeToFit(width: 800, height: 600)
                }
            }
        }
    }
}
