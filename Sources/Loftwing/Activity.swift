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

/// An activity corresponds to a "screen" the user can enter and exit.
/// An application is made of a stack of activity.
public protocol Activity: AnyObject {
    /// Run for one frame.
    func frame(canvas: Canvas)

    /// Resize the activity content to given dimensions.
    func resizeToFit(width: Float, height: Float)

    /// Called when the activity is created for the first time and fully operational:
    /// content has been mounted, activity is on the stack and must be considered visible
    /// to the user.
    func onCreate()
}

/// Activitiy containing one top-level view.
/// You can define it by redefining the content property.
open class ContentActivity: Activity {
    /// The top-level view of that activity.
    open var content: View {
        EmptyView()
    }

    var mountedContent: View?

    public init() {
        // Mount content
        self.mountedContent = self.content

        // Call creation "event"
        self.onCreate()
    }

    /// Runs the activity for one frame.
    public func frame(canvas: Canvas) {
        // Draw the mounted view.
        self.mountedContent?.frame(canvas: canvas)
    }

    public func resizeToFit(width: Float, height: Float) {
        self.mountedContent?.width(width.dip)
        self.mountedContent?.height(height.dip)
    }

    open func onCreate() {
        // Nothing to do
    }
}

/// An empty activity.
class EmptyActivity: Activity {
    func resizeToFit(width: Float, height: Float) {
        // Nothing to do
    }

    func frame(canvas: Canvas) {
        // Nothing to do
    }

    func onCreate() {
        // Nothing to do
    }
}
