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

/// Different image scaling modes.
public enum ScalingMode {
    /// Image is stretched to fit the view dimensions. Aspect ratio is not preserved.
    case stretch

    /// Image is resized and centered to fit the view dimensions, while keeping aspect ratio.
    case fit

    /// Image is centered inside the view but is not resized.
    case center

    // TODO: crop
}

/// Allows displaying an `ImageSource` using different scaling and positioning methods.
public class Image: View, BindableView {
    public var source: ImageSource? = nil {
        didSet {
            self.invalidateLayout()
        }
    }

    /// Where to draw the image. Absolute, computed when the view layout changes.
    var imageRect: Rect?

    /// Should the view dimensions be changed to fit the image?
    let resizeView: Bool

    var scaling = ScalingMode.fit

    var blackPaint: Paint? = nil

    /// Creates a new Image with no source (yet). If `resizeViewToFitImage` is set to `true`,
    /// the view bounds will be resized to fit the image as best as possible.
    @MainActor
    public convenience init(resizeViewToFitImage: Bool = false) {
        self.init(source: nil, resizeViewToFitImage: resizeViewToFitImage)
    }

    /// Creates a new Image with given source. If `resizeViewToFitImage` is set to `true`,
    /// the view bounds will be resized to fit the image as best as possible.
    @MainActor
    public init(source: ImageSource?, resizeViewToFitImage: Bool = false) {
        self.resizeView = resizeViewToFitImage
        self.source = source
    }

    /// Creates a new Image with given unowned source. If `resizeViewToFitImage` is set to `true`,
    /// the view bounds will be resized to fit the image as best as possible.
    @MainActor
    public init<T>(unownedSource: Observable<T?>, resizeViewToFitImage: Bool = false) where T: ImageSource {
        self.resizeView = resizeViewToFitImage
        self.source = unownedSource.value

        super.init()

        unownedSource.observe(owner: self) { newSource in
            self.source = newSource
        }
    }

    /// Sets the scaling mode of the image inside the view.
    /// Default is .fit.
    @discardableResult
    public func scalingMode(_ mode: ScalingMode) -> Self {
        self.scaling = mode
        self.invalidateLayout()
        return self
    }

    /// Measure function for images.
    override public var measureFunc: ViewMeasureFunc {
        { width, widthMode, height, heightMode in
            Logger.debug(debugLayout, "Image measure func called")

            // If we don't want to resize the view, just return whatever Yoga
            // gives us in the first place, it does not matter
            if !self.resizeView {
                return (width, height)
            } else {
                fatalError("Unsupported image settings")
            }
        }
    }

    /// Called after laying out is done. Used to compute the final image position
    /// and dimensions inside the view.
    @MainActor
    override public func onLayout() {
        if let imageSource = self.source {
            Logger.debug(
                debugLayout,
                "Computing layout for a \(imageSource.width)x\(imageSource.height) " +
                "image inside a \(self.width)x\(self.height) view"
            )

            switch self.scaling {
                // Image size == view size
                case .stretch:
                    self.imageRect = self.rect
                // Upscale and center while keeping aspect ratio
                case .fit:
                    if imageSource.width >= imageSource.height {
                        let ratio = imageSource.width / imageSource.height

                        let imageHeight = self.height
                        let imageWidth = imageHeight * ratio

                        let xPosition = (self.width - imageWidth) / 2.0

                        self.imageRect = Rect(x: xPosition, y: self.y, width: imageWidth, height: imageHeight)
                    } else {
                        let ratio = imageSource.height / imageSource.width

                        let imageWidth = self.width
                        let imageHeight = imageWidth * ratio

                        let yPosition = (self.height - imageHeight) / 2.0

                        self.imageRect = Rect(
                            x: self.x,
                            y: yPosition,
                            width: imageWidth,
                            height: imageHeight)
                    }
                // Keep original size, just center
                case .center:
                    let xPosition = (self.width - imageSource.width) / 2.0
                    let yPosition = (self.height - imageSource.height) / 2.0

                    self.imageRect = Rect(
                        x: xPosition,
                        y: yPosition,
                        width: imageSource.width,
                        height: imageSource.height
                    )
            }

            Logger.debug(
                debugLayout,
                "Image position and dimensions are \(self.imageRect!)"
            )
        }
    }

    @MainActor
    override public func draw(canvas: Canvas) {
        if let source = self.source {
            canvas.drawImage(
                source,
                destRect: self.imageRect!,
                paint: nil
            )
        }
    }

    public typealias BindType = Image
    public func bind(_ binding: ViewBinding<BindType>) -> BindType {
        return binding.bind(self)
    }
}
