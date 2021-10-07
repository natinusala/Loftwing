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

// A custom view always inherits Box or View.
class CustomView: Box {
    // Since we are inheriting box, we can use the `content` property
    // to "inflate" ourselves with the desired content. We use the `self.box(_:builder:)`
    // method for that.
    override var content: View {
        self.box(.column) {
            Rectangle(color: Color.yellow)
                .grow(100%)
            Rectangle(color: Color.orange)
                .grow(100%)
        }
    }
}
