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

import Skia

/// A rectangle.
public struct Rect: Equatable {
    public var x: Float {
        didSet {
            self.updateSkRect()
        }
    }
    public var y: Float {
        didSet {
            self.updateSkRect()
        }
    }
    public var width: Float {
        didSet {
            self.updateSkRect()
        }
    }
    public var height: Float {
        didSet {
            self.updateSkRect()
        }
    }

    public internal(set) var skRect: sk_rect_t

    public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height

        self.skRect = sk_rect_t(left: x, top: y, right: x + width, bottom: y + height)
    }

    mutating func updateSkRect() {
        self.skRect = sk_rect_t(left: x, top: y, right: x + width, bottom: y + height)
    }
}

extension sk_rect_t: Equatable {
    public static func == (lhs: sk_rect_t, rhs: sk_rect_t) -> Bool {
        return lhs.top == rhs.top && rhs.bottom == lhs.bottom && rhs.left == lhs.left && rhs.right == lhs.right
    }
}
