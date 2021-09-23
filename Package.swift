// swift-tools-version:5.3

import PackageDescription

// Final package
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
    ],
    targets: [
        // Loftwing targets
        .target(
            name: "Loftwing",
            dependencies: ["GLFW", "Yoga", "NanoVG"]
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
            linkerSettings: [.linkedLibrary("m")]
        ),
        .target(
            name: "Yoga",
            dependencies: ["CYoga"]
        ),
        .target(
            name: "CNanoVG_GL3",
            dependencies: ["GL"],
            cSettings: [.define("NANOVG_GL3")]
        ),
        .target(
            name: "NanoVG",
            // Swap those two lines to change the NanoVG implementation
            dependencies: ["CNanoVG_GL3"],
            swiftSettings: [.define("GL3")]
        ),
        // System libraries
        .systemLibrary(name: "GLFW", pkgConfig: "glfw3"),
        .systemLibrary(name: "GL", pkgConfig: "gl")
    ]
)
