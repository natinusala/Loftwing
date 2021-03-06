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

/// An app is made of multiple layers. Unlike activities, layers are not
/// dynamic - the layers are defined once when the app is created but cannot
/// be pushed or popped.
public protocol Layer {
    /// Triggered when the window size changes so that the layer can resize itself
    /// to given dimensions.
    func resizeToFit(width: Float, height: Float)

    /// Run for one frame.
    func frame(canvas: Canvas)
}
