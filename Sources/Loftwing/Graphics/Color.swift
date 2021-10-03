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
    public let value: UInt32

    /// Creates a color with given RGB values. Alpha will be set to 255 (fully opaque).
    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.init(255, red, green, blue)
    }

    /// Creates a color with given ARGB values.
    public init(_ alpha: UInt8, _ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.value = (UInt32(alpha) << 24) |
            (UInt32(red) << 16) |
            (UInt32(green) << 8) |
            (UInt32(blue) << 0)
    }

    public static let white: Color = Color(255, 255, 255)
    public static let black: Color = Color(0, 0, 0)
    public static let red: Color = Color(255, 0, 0)
    public static let green: Color = Color(0, 255, 0)
    public static let blue: Color = Color(0, 0, 255)
}
