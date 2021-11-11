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

// Find out what GLFW to use
#if os(Windows)
    let glfw = Target.systemLibrary(name: "GLFW", path: "External/GLFWWindows", pkgConfig: "glfw3")
#else
    let glfw = Target.systemLibrary(name: "GLFW", path: "External/GLFWLinux", pkgConfig: "glfw3")
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
        .package(url: "https://github.com/natinusala/Async", .branch("a20ccabfdaf740f14b42eadf46fa9baac882078f")),

        // Testing dependencies
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "9.2.1")),

        .package(path: "External/Tokamak"),
        .package(url: "https://github.com/swift-server/swift-backtrace.git", .upToNextMajor(from: "1.3.1"))
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
                "Rainbow",
                "Async",
                .product(
                    name: "TokamakCore",
                    package: "Tokamak"
                ),
                .product(
                    name: "Backtrace",
                    package: "swift-backtrace"
                ),
            ]
        ),
        .target(
            name: "CLoftwing",
            dependencies: [
                "GLFW",
                "Glad"
            ]
        ),
        .target(
            name: "LoftwingExample",
            dependencies: ["Loftwing"]
        ),
        // Embedded native libraries
        .target(
            name: "CYoga",
            path: "External/CYoga",
            exclude: ["LICENSE"]
        ),
        .target(
            name: "Yoga",
            dependencies: ["CYoga"],
            path: "External/Yoga"
        ),
        .target(
            name: "CGlad",
            path: "External/CGlad"
        ),
        .target(
            name: "Glad",
            dependencies: ["CGlad"],
            path: "External/Glad"
        ),
        // System libraries
        glfw,
        .systemLibrary(name: "Skia", path: "External/Skia", pkgConfig: debugSkia ? "skia_loftwing_debug" : "skia_loftwing"),

        // Test targets
        .target(
            name: "Impostor",
            path: "External/Impostor"
        ),
        .testTarget(
            name: "LoftwingTests",
            dependencies: ["Loftwing", "Quick", "Nimble", "Impostor"]
        )
    ]
)
