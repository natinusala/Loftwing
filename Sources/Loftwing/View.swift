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

import Skia // TODO: remove

/// Protocol for bindable views. Set the BindType typealias to yourself, then
/// write `return binding.bind(self)` in `bind(_ binding:)`.
public protocol BindableView {
    associatedtype BindType: View

    /// Binds the view to the given binding. Allows to get a handle of the view
    /// inside an activity or the parent view.
    func bind(_ binding: ViewBinding<BindType>) -> BindType
}

/// A view is the basic building block of an application's UI.
/// The whole UI is made of a tree of views.
open class View: FrameProtocol {
    public init() {}

    /// Called every frame. Do not override to draw your view's content, override
    /// `draw()` instead.
    open func frame(canvas: Canvas) {
        // Draw the view
        self.draw(canvas: canvas)
    }

    /// Called every frame to draw the view onscreen. Views may not draw outside of
    /// their bounds, they can be clipped if they do so.
    open func draw(canvas: Canvas) {

    }
}

/// Allows to get a handle of a view inside a view or inside an activity.
/// Use the projected value ($ operator) with the `bind()` method of any
/// view to get its handle.
@propertyWrapper
public class ViewBinding<WrappedType: View> {
    var view: WrappedType?

    public init() {
        self.view = nil
    }

    public init(view: WrappedType?) {
        self.view = view
    }

    /// Returns the bound view reference.
    public var wrappedValue: WrappedType? {
        self.view
    }

    /// Returns the ViewBinding handle.
    public var projectedValue: ViewBinding<WrappedType> {
        return self
    }

    /// Called by a view `bind()` method to bind itself to that
    /// binding.
    public func bind(_ view: WrappedType) -> WrappedType {
        if let boundView = self.view {
            Logger.warning(
                "View \(boundView) already bound, previous binding will be lost"
            )
        }

        self.view = view
        return view
    }
}

/// An empty view that does not draw anything onscreen.
public class EmptyView: View, BindableView {
    public typealias BindType = EmptyView
    public func bind(_ binding: ViewBinding<BindType>) -> BindType {
        return binding.bind(self)
    }
}

/// A simple colored rectangle.
public class Rectangle: View, BindableView {
    let paint: Paint

    public init(color: Color) {
        self.paint = Paint(color: color)
    }

    open override func draw(canvas: Canvas) {
        // TODO: draw a rect instead
        canvas.drawPaint(self.paint)
    }

    public typealias BindType = Rectangle
    public func bind(_ binding: ViewBinding<BindType>) -> BindType {
        return binding.bind(self)
    }
}
