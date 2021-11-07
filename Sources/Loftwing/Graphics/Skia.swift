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

/// Used to call the right Skia functions.
public protocol SkiaFunctions {
    func imageNewFromTexture(
        _ context: OpaquePointer?,
        _ texture: OpaquePointer?,
        _ origin: gr_surfaceorigin_t,
        _ colorType: sk_colortype_t,
        _ alpha: sk_alphatype_t,
        _ colorSpace: OpaquePointer?,
        _ releaseProc: sk_image_texture_release_proc?,
        _ releaseContext: UnsafeMutableRawPointer?
    ) -> OpaquePointer?

    func backendTextureIsValid(_ texture: OpaquePointer?) -> Bool
    func backendTextureDelete(_ texture: OpaquePointer?)
}

/// The real Skia functions.
class RealSkiaFunctions: SkiaFunctions {
    func imageNewFromTexture(
        _ context: OpaquePointer?,
        _ texture: OpaquePointer?,
        _ origin: gr_surfaceorigin_t,
        _ colorType: sk_colortype_t,
        _ alpha: sk_alphatype_t,
        _ colorSpace: OpaquePointer?,
        _ releaseProc: sk_image_texture_release_proc?,
        _ releaseContext: UnsafeMutableRawPointer?
    ) -> OpaquePointer? {
        sk_image_new_from_texture(
            context,
            texture,
            origin,
            colorType,
            alpha,
            colorSpace,
            releaseProc,
            releaseContext
        )
    }

    func backendTextureIsValid(_ texture: OpaquePointer?) -> Bool {
        return gr_backendtexture_is_valid(texture)
    }

    func backendTextureDelete(_ texture: OpaquePointer?) {
        return gr_backendtexture_delete(texture)
    }
}

/// The handle to loaded Skia functions. Test targets override this
/// with a mock of their own.
public var skia: SkiaFunctions = RealSkiaFunctions()
