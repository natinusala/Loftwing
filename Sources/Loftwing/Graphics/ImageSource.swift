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
import Glad

/// Represents a source for an image.
public protocol ImageSource {
    /// Pointer to the native Skia image.
    var skImage: OpaquePointer? { get }

    var width: Float { get }
    var height: Float { get }

    /// Area to draw inside the source.
    var drawRect: Rect { get }
}

/// Origin position for GPU textures.
public enum Origin {
    case topLeft
    case bottomLeft

    var skOrigin: gr_surfaceorigin_t {
        switch self {
            case .topLeft:
                return TOP_LEFT_GR_SURFACE_ORIGIN
            case .bottomLeft:
                return BOTTOM_LEFT_GR_SURFACE_ORIGIN
        }
    }
}

/// An image source backed by a GPU texture with fixed width, height and pixel format.
/// Use the `texture` property to get the GPU texture handle.
public class GPUTexture: ImageSource {
    public var skImage: OpaquePointer? = nil

    public var skiaTexture: OpaquePointer? = nil
    public var texture: UInt32 = 0

    public let width: Float
    public let height: Float

    let pixelFormat: PixelFormat

    public let drawRect: Rect

    /// Creates a new GPU texture.
    public init(
        width: Float,
        height: Float,
        pixelFormat: PixelFormat,
        origin: Origin = .topLeft,
        drawRect: Rect? = nil
    ) throws {
        self.pixelFormat = pixelFormat

        self.drawRect = drawRect ?? Rect(x: 0, y: 0, width: width, height: height)

        // In the case of a GPU texture, the width and height of the Skia image
        // should be the same as the input rect
        self.width = self.drawRect.width
        self.height = self.drawRect.height

        // Create the texture and Skia image
        // Be careful to give the actual requested dimensions and not
        // the dimensions of the Skia image (self.drawRect)
        switch (getContext().graphicsAPI) {
            case .gl:
                try self.createGl(width: width, height: height)
        }

        if self.skiaTexture == nil {
            throw GPUTextureError.unableToCreateSkiaTexture
        }

        if !gr_backendtexture_is_valid(self.skiaTexture) {
            throw GPUTextureError.invalidTexture
        }

        guard let context = getContext().skContext else {
            throw GPUTextureError.invalidContext
        }

        // Create a new Skia image
        self.skImage = sk_image_new_from_texture(
            context,
            self.skiaTexture,
            origin.skOrigin,
            self.pixelFormat.skiaColorType,
            OPAQUE_SK_ALPHATYPE, // TODO: handle alpha somehow
            getContext().colorSpace,
            {_ in},
            nil
        )

        if self.skImage == nil {
            throw GPUTextureError.unableToCreateSkiaImage
        }

        Logger.debug(debugGraphics, "Created a new \(pixelFormat) texture of \(width)x\(height)")
    }

    private func createGl(
        width: Float,
        height: Float
    ) throws {
        // Generate a new GL texture
        glGenTextures(1, &self.texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.texture)
        glTexStorage2D(
            GLenum(GL_TEXTURE_2D),
            1,
            pixelFormat.glInternalFormat,
            Int32(width),
            Int32(height)
        )

        // Generate a new Skia backend texture
        var textureInfo = gr_gl_textureinfo_t(
            fTarget: UInt32(GL_TEXTURE_2D),
            fID: self.texture,
            fFormat: pixelFormat.glInternalFormat
        )

        self.skiaTexture = gr_backendtexture_new_gl(
            Int32(width),
            Int32(height),
            false, // mipmapped
            &textureInfo
        )
    }

    deinit {
        if self.skiaTexture != nil {
            gr_backendtexture_delete(self.skiaTexture) // TODO: does that also release the gl texture? probably not
        }
    }
}

/// Different GPU textures pixel formats.
public enum PixelFormat {
    case rgb565
    case rgba8888

    var glInternalFormat: GLenum {
        switch self {
            case .rgb565:
                return GLenum(GL_RGB565)
            case .rgba8888:
                return GLenum(GL_RGBA8)
        }
    }

    var glFormat: GLenum {
        switch self {
            case .rgb565, .rgba8888:
                return GLenum(GL_RGB)
        }
    }

    var glType: GLenum {
        switch self {
            case .rgb565:
                return GLenum(GL_UNSIGNED_SHORT_5_6_5)
            case .rgba8888:
                return GLenum(GL_UNSIGNED_BYTE)
        }
    }

    var skiaColorType: sk_colortype_t {
        switch self {
            case .rgb565:
                return RGB_565_SK_COLORTYPE
            case .rgba8888:
                return RGBA_8888_SK_COLORTYPE
        }
    }
}

/// GPU texture errors.
public enum GPUTextureError: Error {
    case unableToCreateSkiaTexture
    case unableToCreateSkiaImage
    case invalidTexture
    case invalidContext
}

/// Represents a two-dimensional pixels array that you can write to.
public class Bitmap: GPUTexture {
    /// Writes content of given unsafe raw buffer to the bitmap.
    /// It is assumed that the pixels are in the correct pixel format, and that the buffer
    /// contains just enough pixels for a bitmap of the given dimensions (+ pitch).
    /// Pixels are copied and don't need to live after this function returns.
    public func write(
        data: UnsafeRawPointer,
        pitch: Int
    ) {
        switch getContext().graphicsAPI {
            case .gl:
                glBindTexture(GLenum(GL_TEXTURE_2D), self.texture)
                glBindBuffer(GLenum(GL_PIXEL_UNPACK_BUFFER), 0)

                glPixelStorei(GLenum(GL_UNPACK_ROW_LENGTH), GLint(pitch) >> 1)
                glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 2)

                glTexSubImage2D(
                    GLenum(GL_TEXTURE_2D),
                    0,
                    0,
                    0,
                    GLsizei(self.width),
                    GLsizei(self.height),
                    self.pixelFormat.glFormat,
                    self.pixelFormat.glType,
                    data
                )
        }
    }
}
