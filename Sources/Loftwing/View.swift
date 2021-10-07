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

import Yoga

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
    let ygNode: YGNodeRef

    var parent: View? = nil {
        willSet(newParent) {
            if self.parent != nil {
                fatalError("Cannot attach a view to multiple parents")
            }
        }
    }

    // If set to true, the view will be laid out again at next frame.
    var dirty = false

    /// Position of the view on the X axis.
    private(set) var x: Float = 0

    /// Position of the view on the Y axis.
    private(set) var y: Float = 0

    /// Width of the view.
    private(set) var width: Float = 0

    /// Height of the view.
    private(set) var height: Float = 0

    /// Called by the parent view when their layout changes.
    /// Discards calculated layout properties so that they will be
    /// calculated again the next time we request them (usually next frame).
    open func onLayoutChanged(parentX: Float, parentY: Float) {
        self.x = parentX + YGNodeLayoutGetLeft(self.ygNode)
        self.y = parentY + YGNodeLayoutGetTop(self.ygNode)
        self.width = YGNodeLayoutGetWidth(self.ygNode)
        self.height = YGNodeLayoutGetHeight(self.ygNode)

        self.dirty = false

        Logger.debug(
            debugLayout, (
                "\(self) layout validated, new dimensions are (\(self.x),\(self.y)), " +
                "width and height are (\(self.width), \(self.height))"
            )
        )
    }

    /// Called at the beginning of a frame when the view is dirty. Recalculates
    /// the layout and propagates the change through the whole tree if needed.
    open func layout() {
        // Don't layout if we have a parent, instead wait for our parent to layout
        if self.parent != nil {
            return
        }

        Logger.debug(debugLayout, "\(self) layout triggered")

        // Calculate the new layout
        YGNodeCalculateLayout(self.ygNode, YGUndefined, YGUndefined, YGDirectionLTR)

        // Mark ourselves as clean again
        // Use 0,0 as parent coordinates since we are guaranteed to be the
        // top-most view in the tree
        self.onLayoutChanged(parentX: 0, parentY: 0)
    }

    public init() {
        self.ygNode = YGNodeNew()
    }

    /// Called every frame. Do not override to draw your view's content, override
    /// `draw()` instead.
    open func frame(canvas: Canvas) {
        // Layout if needed
        if self.dirty {
            self.layout()
        }

        // Don't do anything if the view size is 0
        if self.width == 0 || self.height == 0 {
            return
        }

        // Draw the view
        self.draw(canvas: canvas)
    }

    /// Called every frame to draw the view onscreen. Views may not draw outside of
    /// their bounds, they can be clipped if they do so.
    open func draw(canvas: Canvas) {
        // Does nothing by default
    }

    /// Invalidates the view, triggering a layout recalculation of the whole view tree
    /// starting from the top-most parent.
    func invalidateLayout() {
        // TODO: mark the yoga node as dirty (why?)

        // Invalidate every view of the tree, going upwards from this one
        // The point is that the top-most view will be laid out at next frame
        // marking every child as clean again
        if let parent = self.parent {
            parent.invalidateLayout()
        }
        // We are the top-most view, invalidate ourselves
        else {
            // Invalidate ourselves
            Logger.debug(debugLayout, "\(self) layout invalidated")
            self.dirty = true
        }
    }

    /// Sets the preferred width of the view. This will not always be the final
    /// width depending on layout settings and surrounding views.
    /// Use nil to have the layout automatically resize the view.
    @discardableResult
    public func width(_ width: DIP?) -> Self {
        YGNodeStyleSetMinWidthPercent(self.ygNode, 0)

        if let width = width {
            YGNodeStyleSetWidth(self.ygNode, width.value)
            YGNodeStyleSetMinWidth(self.ygNode, width.value)
        }
        else {
            YGNodeStyleSetWidthAuto(self.ygNode)
            YGNodeStyleSetMinWidth(self.ygNode, YGUndefined)
        }

        self.invalidateLayout()

        return self
    }

    /// Sets the preferred height of the view. This will not always be the final
    /// width depending on layout settings and surrounding views.
    /// Use nil to have the layout automatically resize the view.
    @discardableResult
    public func height(_ height: DIP?) -> Self {
        YGNodeStyleSetMinHeightPercent(self.ygNode, 0)

        if let height = height {
            YGNodeStyleSetHeight(self.ygNode, height.value)
            YGNodeStyleSetMinHeight(self.ygNode, height.value)
        } else {
            YGNodeStyleSetHeightAuto(self.ygNode)
            YGNodeStyleSetMinHeight(self.ygNode, YGUndefined)
        }

        self.invalidateLayout()

        return self
    }

    /// Sets the growth factor of the view, aka how much of the remaining space
    /// it should take in its parent box axis.
    /// Opposite of shrink.
    /// Default is 0%.
    @discardableResult
    public func grow(_ factor: Percentage) -> Self {
        YGNodeStyleSetFlexGrow(self.ygNode, factor.value)
        self.invalidateLayout()
        return self
    }

    deinit {
        YGNodeFree(self.ygNode)
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
        canvas.drawRect(
            x: self.x,
            y: self.y,
            width: self.width,
            height: self.height,
            paint: self.paint
        )
    }

    public typealias BindType = Rectangle
    public func bind(_ binding: ViewBinding<BindType>) -> BindType {
        return binding.bind(self)
    }
}
