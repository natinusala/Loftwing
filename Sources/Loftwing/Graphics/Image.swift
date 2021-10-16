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

public enum ImageError: Error {
    case unableToCreateImage
    case noTexture
    case invalidTexture
    case invalidContext
}


/// Represents a two-dimensional pixels array, either coming from a picture or
/// a GPU texture.
@MainActor
public protocol Image {
    /// Pointer to the native Skia image.
    var native: OpaquePointer? { get }

    var width: Float { get }
    var height: Float { get }
}

@MainActor
public class GPUTextureImage: Image {
    public let native: OpaquePointer?

    let texture: GPUTexture

    public var width: Float {
        return self.texture.width
    }

    public var height: Float {
        return self.texture.height
    }

    /// Creates a new image from the given GPU texture.
    public init(texture: GPUTexture) throws {
        if texture.native == nil {
            throw ImageError.noTexture
        }

        if !texture.isValid {
            throw ImageError.invalidTexture
        }

        guard let context = getContext().skiaContext else {
            throw ImageError.invalidContext
        }

        self.native = sk_image_new_from_texture(
            context,
            texture.native,
            TOP_LEFT_GR_SURFACE_ORIGIN,
            texture.pixelFormat.skiaColorType,
            OPAQUE_SK_ALPHATYPE, // TODO: handle alpha somehow
            getContext().colorSpace,
            {_ in},
            nil
        )

        if self.native == nil {
            throw ImageError.unableToCreateImage
        }

        self.texture = texture
    }

    // TODO: deinit?
}
