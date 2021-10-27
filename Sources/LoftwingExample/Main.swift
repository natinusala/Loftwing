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

import Loftwing

// Declare a Loftwing application.
@main
class ExampleApplication: Application {
    /// XXX: Required to prevent:
    /// "SIL verification failed: cannot call an async function from a non async function"
    required public init() async {
        await super.init()
    }

    // Application title
    override var title: String {
        "Loftwing Example Application"
    }

    // Initial window mode and size
    override var initialWindowMode: WindowMode {
        .windowed(1280, 720)
    }

    // Initial graphics API, nil being "select automatically"
    override var initialGraphicsAPI: GraphicsAPI? {
        nil
    }

    // First activity to be pushed when the app starts
    override var mainActivity: Activity {
        MainActivity()
    }
}
