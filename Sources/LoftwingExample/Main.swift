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
    /// Called when the app gets initialized.
    required init() {

    }

    // Application title
    var title: String {
        "Loftwing Example Application"
    }

    // Initial window mode and size
    var initialWindowMode: WindowMode {
        .windowed(1280, 720)
    }

    // Initial graphics API, nil being "select automatically"
    var initialGraphicsAPI: GraphicsAPI? {
        nil
    }

    // First activity to be pushed when the app starts
    var mainActivity: Activity {
        MainActivity()
    }
}
