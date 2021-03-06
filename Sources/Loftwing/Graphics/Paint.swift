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

public enum FilteringQuality {
    /// Nearest pixel.
    case none

    /// Bilinear filtering.
    case low

    /// Bilinear filtering with mipmaps for downscaling.
    case medium

    /// Bicubic filtering.
    case high

    var skiaFilterQuality: sk_filter_quality_t {
        switch self {
            case .none:
                return NONE_SK_FILTER_QUALITY
            case .low:
                return LOW_SK_FILTER_QUALITY
            case .medium:
                return MEDIUM_SK_FILTER_QUALITY
            case .high:
                return HIGH_SK_FILTER_QUALITY
        }
    }
}

/// A paint represents the aspect and style of everything drawn onscreen. It can be
/// an image, a color, it can have effects...
public class Paint {
    public let native: OpaquePointer

    /// Creates a paint with default values.
    public init() {
        self.native = sk_paint_new()
    }

    /// Creates a paint with given color.
    public init(color: Color) {
        self.native = sk_paint_new()
        self.setColor(color)
    }

    /// Sets the paint color.
    public func setColor(_ color: Color) {
        sk_paint_set_color(self.native, color.value)
    }

    /// Sets the filtering quality.
    public func setFilteringQuality(_ quality: FilteringQuality) {
        sk_paint_set_filter_quality(self.native, quality.skiaFilterQuality)
    }

    deinit {
        sk_paint_delete(self.native)
    }
}
