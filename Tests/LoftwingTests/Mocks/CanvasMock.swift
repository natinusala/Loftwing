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

@testable import Loftwing

class CanvasMock: Mock<Canvas>, Canvas {
    func drawPaint(_ paint: Paint) {
        record(args: [paint])
    }

    func drawRect(
        _ rect: Rect,
        paint: Paint
    ) {
        record(args: [rect, paint])
    }

    func drawImage(
        _ image: ImageSource,
        x: Float,
        y: Float,
        paint: Paint?
    ) {
        record(args: [image, x, y, paint])
    }

    func drawImage(
        _ image: ImageSource,
        destRect: Rect,
        paint: Paint?
    ) {
        record(args: [image, destRect, paint])
    }
}
