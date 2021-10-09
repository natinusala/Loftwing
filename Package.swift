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
        .package(url: "https://github.com/manuelCarlos/Easing.git", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        // Loftwing targets
        .target(
            name: "Loftwing",
            dependencies: [
                "Yoga",
                "GLFW",
                "GL",
                "Skia",
                "Rainbow",
                "Easing",
            ]
        ),
        .target(
            name: "LoftwingExample",
            dependencies: ["Loftwing"]
        ),
        .testTarget(
            name: "LoftwingTests",
            dependencies: ["Loftwing"]
        ),
        // Embedded native libraries
        .target(
            name: "CYoga",
            path: "External/CYoga",
            exclude: ["LICENSE"],
            linkerSettings: [.linkedLibrary("m")]
        ),
        .target(
            name: "Yoga",
            dependencies: ["CYoga"],
            path: "External/Yoga"
        ),
        // System libraries
        .systemLibrary(name: "GLFW", path: "External/GLFW", pkgConfig: "glfw3"),
        .systemLibrary(name: "GL", path: "External/GL", pkgConfig: "gl"),
        .systemLibrary(name: "Skia", path: "External/Skia", pkgConfig: "skia_loftwing")
    ]
)
