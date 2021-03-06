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

// This is the first activity to be pushed when the application
// starts.
class MainActivity: ContentActivity {
    override var content: View {
        Box(.row) {
            Rectangle(color: Color.red)
                .grow(100%)
            Rectangle(color: Color.blue)
                .grow(100%)
            Rectangle(color: Color.green)
                .grow(100%)
            CustomView()
                .grow(100%)
        }
    }

    /// Called when the activity is initialized and ready to be used.
    override func onCreate() {
        Logger.info("Example activity created")
    }
}
