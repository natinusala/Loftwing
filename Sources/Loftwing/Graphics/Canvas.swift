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

/// A canvas is the handle used to draw everything onscreen.
public class Canvas {
    let native: OpaquePointer

    init(nativeCanvas: OpaquePointer) {
        self.native = nativeCanvas
    }

    /// Draws the given paint on the whole canvas.
    public func drawPaint(_ paint: Paint) {
        sk_canvas_draw_paint(self.native, paint.native)
    }

    /// Draws the given paint in the given rectangle region.
    public func drawRect(
        x: Float,
        y: Float,
        width: Float,
        height: Float,
        paint: Paint
    ) {
        var rect = sk_rect_t(left: x, top: y, right: x + width, bottom: y + height)

        sk_canvas_draw_rect(
            self.native,
            &rect,
            paint.native
        )
    }
}
