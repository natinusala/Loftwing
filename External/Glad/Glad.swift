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

@_exported import CGlad

// Glad header uses defines to translate glad_ symbols, however Swift C interop
// ignores defines so we need to do the translation here.
// gladLoaderLoadGL() needs to be called before using those.

public let glBindTexture = glad_glBindTexture!
public let glPixelStorei = glad_glPixelStorei!
public let glBindBuffer = glad_glBindBuffer!
public let glTexSubImage2D = glad_glTexSubImage2D!
public let glGenTextures = glad_glGenTextures!
public let glTexStorage2D = glad_glTexStorage2D!
public let glEnable = glad_glEnable!
