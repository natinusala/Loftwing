// Import (and export) the right NanoVG implementation
#if GL3
@_exported import CNanoVG_GL3
#endif

/// Flag indicating if geometry based anti-aliasing is used (may not be needed when using MSAA).
public let NVG_ANTIALIAS: Int32 = 1<<0

/// Flag indicating if strokes should be drawn using stencil buffer. The rendering will be a little
/// slower, but path overlaps (i.e. self-intersecting or sharp turns) will be drawn just once.
public let NVG_STENCIL_STROKES: Int32 = 1<<1

/// Flag indicating that additional debug checks are done.
public let NVG_DEBUG: Int32 = 1<<2

/// NanoVG context wrapper.
public class NVGContext {
    private var vg: OpaquePointer

    public init?(flags: Int32) {
#if GL3
        guard let vg = nvgCreateGL3(flags) else {
            return nil
        }
#endif

        self.vg = vg
    }

    public func beginFrame(windowWidth: Float, windowHeight: Float, devicePixelRatio: Float) -> NVGFrame {
        return NVGFrame(
            self.vg,
            windowWidth: windowWidth,
            windowHeight: windowHeight,
            devicePixelRatio: devicePixelRatio
        )
    }

    deinit {
#if GL3
        nvgDeleteGL3(self.vg)
#endif
    }
}

/// Nanovg frame wrapper.
public class NVGFrame {
    private let vg: OpaquePointer

    fileprivate init(
        _ vg: OpaquePointer,
        windowWidth: Float,
        windowHeight: Float,
        devicePixelRatio: Float
    ) {
        self.vg = vg

        nvgBeginFrame(self.vg, windowWidth, windowHeight, devicePixelRatio)
    }

    public func beginPath() -> NVGPath {
        return NVGPath(self.vg)
    }

    public func end() {
        nvgEndFrame(self.vg)
    }
}

/// NanoVG path wrapper.
public class NVGPath {
    private let vg: OpaquePointer

    fileprivate init(_ vg: OpaquePointer) {
        self.vg = vg
    }

    public func rect(x: Float, y: Float, width: Float, height: Float) -> NVGPath {
        nvgRect(self.vg, x, y, width, height)
        return self
    }

    public func fillPaint(_ paint: NVGpaint) -> NVGPath {
        nvgFillPaint(self.vg, paint)
        return self
    }

    public func fillColor(_ color: NVGcolor) -> NVGPath {
        nvgFillColor(self.vg, color)
        return self
    }

    public func fill() -> NVGPath {
        nvgFill(self.vg)
        return self
    }
}
