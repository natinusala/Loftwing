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

import Foundation

import Impostor

@testable import Loftwing

class ActivityMock: EquatableMock<Activity>, Activity {
    let creationEvent: Event<Void> = EventMock<Void>()

    func mountContent() {
        record()
    }

    func resizeToFit(width: Float, height: Float) {
        record(args: [width, height])
    }

    func frame(canvas: Canvas) {
        record()
    }

    func onCreate() {
        record()
    }
}
