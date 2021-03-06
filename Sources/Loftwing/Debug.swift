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

// Those flags are used to toggle debug messages of various components of the
// library at compile time. Please set them all to `false` before commiting.

/// Set to `true` to enable debug messages of the layout engine.
let debugLayout = false

/// Set to `true` to enable debug message of events and tasks.
let debugEvents = false

/// Set to `true` to enable debug message of animations.
let debugAnimations = false

/// Set to `true` to enable debug message of all tickings.
let debugTickings = false || debugAnimations || debugEvents

/// Set to `true` to enable debug messages of graphics rendering.
let debugGraphics = false

/// Sets to `true` to enable error messages of graphics API.
let debugRenderer = false
