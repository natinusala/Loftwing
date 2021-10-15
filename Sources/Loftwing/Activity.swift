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
///
/// Each activity contains one top-level view. You can define it by redefining
/// the content property.
open class Activity: FrameProtocol {
    /// The top-level view of that activity.
    open var content: View {
        EmptyView()
    }

    var mountedContent: View? = nil

    let creationEvent = Event<Void>()

    public init() {
        // Observe our own creation event
        self.creationEvent.observe(owner: self) {
            await self.onCreate()
        }
    }

    /// Runs the activity for one frame.
    @MainActor
    public func frame(canvas: Canvas) {
        // Draw the mounted view.
        if let mountedView = self.mountedContent {
            mountedView.frame(canvas: canvas)
        }
    }

    /// Executed once when the activity is created.
    open func onCreate() async {}

    /// Creates the content tree and stores it in the activity.
    func mountContent() {
        // Never mount content twice
        if self.mountedContent != nil {
            Logger.error("Cannot mount activity content twice")
            fatalError()
        }

        self.mountedContent = self.content
    }

    /// Resize the activity content to given dimensions.
    func resizeToFit(width: Float, height: Float) {
        if let mountedContent = self.mountedContent {
            mountedContent.width(width.dip)
            mountedContent.height(height.dip)
        }
    }
}

/// An empty activity.
class EmptyActivity: Activity {
    override var content: View {
        EmptyView()
    }
}
