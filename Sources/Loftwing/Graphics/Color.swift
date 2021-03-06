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

/// An ARGB color.
public struct Color {
    /// ARGB value.
    public let value: UInt32

    /// Creates a color with given RGB values. Alpha will be set to 255 (fully opaque).
    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.init(255, red, green, blue)
    }

    /// Creates a color with given ARGB values. Assumes given value are all
    /// between 0 and 255.
    public init(_ alpha: UInt8, _ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.value = (UInt32(alpha) << 24) |
            (UInt32(red) << 16) |
            (UInt32(green) << 8) |
            (UInt32(blue) << 0)
    }

    /// Creates a color with given ARGB UInt32 value.
    public init(_ value: UInt32) {
        self.value = value
    }

    public static let white = Color(255, 255, 255)
    public static let black = Color(0, 0, 0)
    public static let red = Color(255, 0, 0)
    public static let green = Color(0, 255, 0)
    public static let blue = Color(0, 0, 255)
    public static let yellow = Color(255, 255, 0)
    public static let orange = Color(255, 165, 0)
}
