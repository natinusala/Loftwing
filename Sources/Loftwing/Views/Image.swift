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

import Foundation

/// Different image scaling modes.
public enum ScalingMode {
    /// Image is stretched to fit the view dimensions. Aspect ratio is not preserved.
    case stretch

    /// Image is resized and centered to fit the view dimensions, while keeping aspect ratio.
    case fit

    /// Image is centered inside the view but is not resized.
    case center

    /// Integer scaling. Can specify scaling factor, or use `nil` to scale up as much
    /// as possible.
    case integer(Int?)

    // TODO: crop
}

/// Different image sampling modes.
public enum SamplingMode {
    case nearest
    case bilinear
    case bicubic

    var filteringQuality: FilteringQuality {
        switch self {
            case .nearest:
                return .none
            case .bilinear:
                return .medium
            case .bicubic:
                return .high
        }
    }
}

/// Allows displaying an `ImageSource` using different scaling and positioning methods.
public class Image: View, BindableView {
    public var source: ImageSource? {
        didSet {
            self.invalidateLayout()
        }
    }

    /// Where to draw the image. Absolute, computed when the view layout changes.
    var imageRect: Rect = Rect(x: 0, y: 0, width: 0, height: 0)

    /// Should the view dimensions be changed to fit the image?
    let resizeView: Bool

    let paint: Paint

    var scaling = ScalingMode.fit{
        didSet {
            self.invalidateLayout()
        }
    }

    var sampling = SamplingMode.nearest {
        didSet {
            self.paint.setFilteringQuality(self.sampling.filteringQuality)
        }
    }

    /// Creates a new Image with no source (yet). If `resizeViewToFitImage` is set to `true`,
    /// the view bounds will be resized to fit the image as best as possible.
    public convenience init(resizeViewToFitImage: Bool = false) {
        self.init(source: nil, resizeViewToFitImage: resizeViewToFitImage)
    }

    /// Creates a new Image with given source. If `resizeViewToFitImage` is set to `true`,
    /// the view bounds will be resized to fit the image as best as possible.
    public init(source: ImageSource?, resizeViewToFitImage: Bool = false) {
        self.resizeView = resizeViewToFitImage
        self.source = source
        self.paint = Paint()
    }

    /// Creates a new Image with given unowned source. If `resizeViewToFitImage` is set to `true`,
    /// the view bounds will be resized to fit the image as best as possible.
    public init(unownedSource: Observable<ImageSource?>, resizeViewToFitImage: Bool = false) {
        self.resizeView = resizeViewToFitImage
        self.source = unownedSource.value
        self.paint = Paint()

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
        return self
    }

    /// Sets the sampling mode of the image inside the view.
    /// Default is .nearest.
    @discardableResult
    public func samplingMode(_ mode: SamplingMode) -> Self {
        self.sampling = mode
        return self
    }

    /// Measure function for images.
    override public var measureFunc: ViewMeasureFunc {
        { width, widthMode, height, heightMode in
            Logger.debug(debugLayout, "Image measure func called")

            // If we don't want to resize the view, just return undefined
            // dimensions as it does not matter
            if !self.resizeView {
                return (nil, nil)
            } else {
                fatalError("Unsupported image settings")
            }
        }
    }

    /// Called after laying out is done. Used to compute the final image position
    /// and dimensions inside the view.
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
                    let sourceRatio = imageSource.width / imageSource.height
                    let imageRatio = self.width / self.height

                    let dimensions: (width: Float, height: Float) = imageRatio > sourceRatio ?
                        (width: imageSource.width * self.height / imageSource.height, height: self.height) :
                        (width: self.width, height: imageSource.height * self.width / imageSource.width)

                    let xPosition = (self.width - dimensions.width) / 2.0
                    let yPosition = (self.height - dimensions.height) / 2.0

                    self.imageRect = Rect(
                        x: xPosition,
                        y: yPosition,
                        width: dimensions.width,
                        height: dimensions.height
                    )
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
                // Either multiply original image size, or compute the largest scale
                // possible
                case let .integer(factor):
                    var width: Float = 0
                    var height: Float = 0

                    // Scale up
                    if let factor = factor {
                        if factor <= 0 {
                            fatalError("Illegal value \(factor) for integer scaling")
                        }

                        width = imageSource.width * Float(factor)
                        height = imageSource.height * Float(factor)
                    } else {
                        // Get max width
                        let maxWidth = floor(self.width / imageSource.width)
                        let maxHeight = floor(self.height / imageSource.height)

                        let maxFactor = min(maxWidth, maxHeight)

                        width = imageSource.width * Float(maxFactor)
                        height = imageSource.height * Float(maxFactor)
                    }

                    // Center
                    let xPosition = (self.width - width) / 2.0
                    let yPosition = (self.height - height) / 2.0

                    self.imageRect = Rect(
                        x: xPosition,
                        y: yPosition,
                        width: width,
                        height: height
                    )
            }

            Logger.debug(
                debugLayout,
                "Image position and dimensions are \(self.imageRect)"
            )
        }
    }

    override public func draw(canvas: Canvas) {
        if let source = self.source {
            canvas.drawImage(
                source,
                destRect: self.imageRect,
                paint: self.paint
            )
        }
    }

    public typealias BindType = Image
    public func bind(_ binding: ViewBinding<BindType>) -> BindType {
        return binding.bind(self)
    }
}
