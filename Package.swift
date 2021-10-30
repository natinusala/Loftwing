// swift-tools-version:5.3

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
import PackageDescription

/// Should we link against the debug Skia build?
let debugSkia = false

// Platform specific changes
#if os(Windows)
    let yogaLinkerSettings: [LinkerSetting] = []
#else
    let yogaLinkerSettings: [LinkerSetting] = [LinkerSetting.linkedLibrary("m")]
#endif

let package = Package(
    name: "Loftwing",
    products: [
        .library(
            name: "Loftwing",
            targets: ["Loftwing"]
        ),
        .executable(
            name: "LoftwingExample",
            targets: ["Loftwing", "LoftwingExample"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Rainbow.git", .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
        // Loftwing targets
        .target(
            name: "Loftwing",
            dependencies: [
                "CLoftwing",
                "Yoga",
                "GLFW",
                "Glad",
                "Skia",
                "Rainbow"
            ]
        ),
        .target(
            name: "CLoftwing",
            dependencies: ["GLFW", "CGlad"]
        ),
        .target(
            name: "LoftwingExample",
            dependencies: ["Loftwing"]
        ),
        // Embedded native libraries
        .target(
            name: "CYoga",
            path: "External/CYoga",
            exclude: ["LICENSE"],
            linkerSettings: yogaLinkerSettings
        ),
        .target(
            name: "Yoga",
            dependencies: ["CYoga"],
            path: "External/Yoga"
        ),
        .target(
            name: "Glad",
            dependencies: ["CGlad"],
            path: "External/Glad"
        ),
        .target(
            name: "CGlad",
            path: "External/CGlad"
        ),
        // System libraries
        .systemLibrary(name: "GLFW", path: "External/GLFW", pkgConfig: "glfw3"),
        .systemLibrary(name: "Skia", path: "External/Skia", pkgConfig: debugSkia ? "skia_loftwing_debug" : "skia_loftwing"),
        // Test targets
        // TODO: Use Quick + Nimble once it has full async support
        // Not even XCTest has async support, what's the point?
        // .testTarget(
        //     name: "LoftwingTests",
        //     dependencies: ["Loftwing"]
        // ),
    ]
)
