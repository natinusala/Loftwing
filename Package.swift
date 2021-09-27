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
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "4.0.0"))
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
