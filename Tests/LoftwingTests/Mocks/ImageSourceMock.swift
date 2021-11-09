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

class GPUTextureMock: GPUTexture {
    let mock = Mock<GPUTexture>()

    override func createGl(
        width: Float,
        height: Float
    ) throws {
        mock.record(args: [width, height])
        self.skiaTexture = OpaquePointer(bitPattern: 1234)
    }
}

class ImageSourceMock: Mock<ImageSource>, ImageSource {
    let skImage = OpaquePointer(bitPattern: 1234)

    let width: Float
    let height: Float

    let drawRect = Rect(x: 100, y: 100, width: 200, height: 200)

    init(width: Float = 800, height: Float = 600) {
        self.width = width
        self.height = height
    }
}
