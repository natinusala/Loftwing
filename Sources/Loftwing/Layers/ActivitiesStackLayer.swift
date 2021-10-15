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

/// The "main" layer of an app: the activities stack.
class ActivitiesStackLayer: Layer {
    var stack: ActivitiesStack = ActivitiesStack()

    @MainActor
    func frame(canvas: Canvas) {
        // Draw all activities
        // TODO: do it better (see brls)
        for activity in self.stack {
            // TODO: saveLayer and restore?
            activity.frame(canvas: canvas)
        }
    }

    /// Pushes an activity on the stack.
    func push(activity: Activity) async {
        await self.stack.push(activity: activity)
    }

    func resizeToFit(width: Float, height: Float) {
        Logger.debug(debugLayout, "Resizing every activity to fit \(width)x\(height)")
        for activity in self.stack {
            activity.resizeToFit(width: width, height: height)
        }
    }
}

/// Responsible for pushing and popping activities from the stack, as well
/// as handling activities lifecycles.
class ActivitiesStack: Sequence {
    var stack: [Activity] = []

    func push(activity: Activity) async {
        self.stack.append(activity)

        // Set activity content view
        activity.mountContent()

        // Fire creation event
        await activity.creationEvent.fire()
    }

    typealias Iterator = Array<Activity>.Iterator
    typealias Element = Activity
    func makeIterator() -> Iterator {
        return self.stack.makeIterator()
    }
}
