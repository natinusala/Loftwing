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

class ColorSpec: QuickSpec {
    override func spec() {
        describe("a color") {
            it("can be initialized with RGB components") {
                let color = Color(124, 57, 197)
                expect(color.value).to(equal(0xFF7C39C5))
            }

            it("can be initialized with ARGB components") {
                let color = Color(50, 90, 211, 48)
                expect(color.value).to(equal(0x325AD330))
            }

            it("can be initialized with raw ARGB value") {
                let color = Color(255, 174, 33, 69)
                expect(color.value).to(equal(0xFFAE2145))
            }
        }
    }
}
