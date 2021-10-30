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

public enum GPUTextureError: Error {
    case unableToCreateTexture
}

/// Different GPU textures pixel formats.
public enum PixelFormat {
    case rgb565

    var glInternalFormat: GLenum {
        switch self {
            case .rgb565:
                return GLenum(GL_RGB565)
        }
    }

    var glFormat: GLenum {
        switch self {
            case .rgb565:
                return GLenum(GL_RGB)
        }
    }

    var glType: GLenum {
        switch self {
            case .rgb565:
                return GLenum(GL_UNSIGNED_SHORT_5_6_5)
        }
    }

    var skiaColorType: sk_colortype_t {
        switch self {
            case .rgb565:
                return RGB_565_SK_COLORTYPE
        }
    }
}

/// Represents a GPU texture, with an associated FBO to draw on it.
@MainActor
public class GPUTexture {
    var native: OpaquePointer? = nil

    var glTexture: GLuint = 0

    public private(set) var width: Float = 0
    public private(set) var height: Float = 0
    public private(set) var pixelFormat: PixelFormat = .rgb565

    public init() {}

    /// Resets the GPU texture with given width and height.
    public func reset(width: Float, height: Float, pixelFormat: PixelFormat) throws {
        // Destroy existing texture if any
        if self.native != nil {
            gr_backendtexture_delete(self.native) // TODO: does that also release the gl texture?
            self.native = nil
        }

        // Create a new texture
        switch getContext().graphicsAPI {
            case .gl:
                try self.createGl(width: width, height: height, pixelFormat: pixelFormat)
        }

        if self.native == nil {
            throw GPUTextureError.unableToCreateTexture
        }

        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat

        Logger.debug(debugGraphics, "Created a new \(pixelFormat) texture of \(width)x\(height)")
    }

    /// Writes content of given unsafe raw buffer to the texture.
    /// Pixels are copied and don't need to live after this function returns.
    public func write(
        data: UnsafeRawPointer,
        width: Float,
        height: Float,
        pitch: Int,
        pixelFormat: PixelFormat
    ) {
        switch getContext().graphicsAPI {
            case .gl:
                glBindTexture(GLenum(GL_TEXTURE_2D), self.glTexture)
                glBindBuffer(GLenum(GL_PIXEL_UNPACK_BUFFER), 0)

                glPixelStorei(GLenum(GL_UNPACK_ROW_LENGTH), GLint(pitch) >> 1)
                glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 2)

                glTexSubImage2D(
                    GLenum(GL_TEXTURE_2D),
                    0,
                    0,
                    0,
                    GLsizei(width),
                    GLsizei(height),
                    pixelFormat.glFormat,
                    pixelFormat.glType,
                    data
                )
        }
    }

    private func createGl(width: Float, height: Float, pixelFormat: PixelFormat) throws {
        // Generate a new GL texture
        glGenTextures(1, &self.glTexture)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.glTexture)
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
            fID: self.glTexture,
            fFormat: pixelFormat.glInternalFormat // TODO: internal or not?
        )

        self.native = gr_backendtexture_new_gl(
            Int32(width),
            Int32(height),
            false, // mipmapped
            &textureInfo
        )
    }

    var isValid: Bool {
        return gr_backendtexture_is_valid(self.native)
    }
}
