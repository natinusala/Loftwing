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

/// The axis of a box.
public enum Axis {
    case column
    case row

    var yogaFlexDirection: YGFlexDirection {
        switch self {
            case .column:
                return YGFlexDirectionColumn
            case .row:
                return YGFlexDirectionRow
        }
    }
}

/// A Box is a view that contains other views and, most importantly,
/// is responsible for laying them out. Layout is done using a flexbox-like
/// system.
open class Box: View {
    var children: [View] = []

    /// The content of that box, statically defined.
    /// Used when creating custom views.
    open var content: View {
        EmptyView()
    }

    /// Creates a box with the given children.
    public init(_ axis: Axis, @BoxBuilder builder: () -> [View]) {
        super.init()

        self.box(axis, builder: builder)
    }

    /// Creates a box with content taken from its `content` property.
    override public init() {
        super.init()

        // Calling self.content will automatically inflate self.children
        // if box(_:builder:) is called at any point
        if let content = self.content as? Box {
            if content !== self {
                fatalError("Box content returned another view than itself")
            }
        }
        else {
            fatalError("Box content returned another view than itself")
        }
    }

    /// Adds the given view to the box.
    public func addView(_ view: View) {
        // Add our link
        self.children.append(view)
        view.parent = self

        // Add Yoga link
        let position = YGNodeGetChildCount(self.ygNode)
        YGNodeInsertChild(self.ygNode, view.ygNode, position)

        self.invalidateLayout()
    }

    /// Inflates the box with the given content. Use with the `content`
    /// property when creating custom views.
    @discardableResult
    public func box(_ axis: Axis, @BoxBuilder builder: () -> [View]) -> Self {
        let children = builder()

        YGNodeStyleSetFlexDirection(self.ygNode, axis.yogaFlexDirection)

        for child in children {
            self.addView(child)
        }

        return self
    }

    @MainActor
    open override func frame(canvas: Canvas) {
        super.frame(canvas: canvas)

        // Run frame of every children
        for child in self.children {
            child.frame(canvas: canvas)
        }
    }

    open override func onLayoutChanged(parentX: Float, parentY: Float) {
        super.onLayoutChanged(parentX: parentX, parentY: parentY)

        // At this point, the position and dimensions properties are set

        // Propagate the signal to every child
        Logger.debug(debugLayout, "Box parent layout changed, propagating to \(self.children.count) child views")
        for child in self.children {
            child.onLayoutChanged(parentX: self.x, parentY: self.y)
        }
    }
}

/// Result builder for Box views.
@resultBuilder
public struct BoxBuilder {
    /// buildBlock for no children.
    public static func buildBlock() -> [View] {
        return []
    }
}

/// Autogenerated by make_box_builder.py.
extension BoxBuilder {
    // buildBlock for 1 child view(s).
    public static func buildBlock<View>(_ v0: View) -> [View] {
        return [v0]
    }

    // buildBlock for 2 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View) -> [View] {
        return [v0, v1]
    }

    // buildBlock for 3 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View) -> [View] {
        return [v0, v1, v2]
    }

    // buildBlock for 4 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View) -> [View] {
        return [v0, v1, v2, v3]
    }

    // buildBlock for 5 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View) -> [View] {
        return [v0, v1, v2, v3, v4]
    }

    // buildBlock for 6 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5]
    }

    // buildBlock for 7 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6]
    }

    // buildBlock for 8 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7]
    }

    // buildBlock for 9 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8]
    }

    // buildBlock for 10 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9]
    }

    // buildBlock for 11 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10]
    }

    // buildBlock for 12 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11]
    }

    // buildBlock for 13 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View, _ v12: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12]
    }

    // buildBlock for 14 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View, _ v12: View, _ v13: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13]
    }

    // buildBlock for 15 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View, _ v12: View, _ v13: View, _ v14: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14]
    }

    // buildBlock for 16 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View, _ v12: View, _ v13: View, _ v14: View, _ v15: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15]
    }

    // buildBlock for 17 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View, _ v12: View, _ v13: View, _ v14: View, _ v15: View, _ v16: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16]
    }

    // buildBlock for 18 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View, _ v12: View, _ v13: View, _ v14: View, _ v15: View, _ v16: View, _ v17: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17]
    }

    // buildBlock for 19 child view(s).
    public static func buildBlock<View>(_ v0: View, _ v1: View, _ v2: View, _ v3: View, _ v4: View, _ v5: View, _ v6: View, _ v7: View, _ v8: View, _ v9: View, _ v10: View, _ v11: View, _ v12: View, _ v13: View, _ v14: View, _ v15: View, _ v16: View, _ v17: View, _ v18: View) -> [View] {
        return [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v16, v17, v18]
    }
}
