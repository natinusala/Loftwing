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

public protocol BindableView {
    associatedtype ViewType: View

    func bind(_ binding: ViewBinding<ViewType>) -> ViewType
}

/// A view is the basic building block of an application's UI.
/// The whole UI is made of a tree of views.
open class View {
    public init() {}
}

/// Allows to get a handle of a view inside a view or inside an activity.
/// Use the projected value ($ operator) with the .bind() method of any
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

    public var wrappedValue: WrappedType? {
        self.view
    }

    public var projectedValue: ViewBinding<WrappedType> {
        return self
    }

    public func bind(_ view: WrappedType) -> WrappedType {
        self.view = view
        return view
    }
}

/// An empty view.
public class EmptyView: View, BindableView {
    public typealias ViewType = EmptyView
    public func bind(_ binding: ViewBinding<ViewType>) -> EmptyView {
        return binding.bind(self)
    }
}
