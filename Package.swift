// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "swift-html-pdf-rendering",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(name: "HTML PDF Rendering", targets: ["HTML PDF Rendering"]),
    ],
    dependencies: [
        .package(path: "../swift-html-rendering"),
        .package(path: "../swift-pdf-rendering"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-standards"),
    ],
    targets: [
        .target(
            name: "HTML PDF Rendering",
            dependencies: [
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
                .product(name: "Standards", package: "swift-standards"),
            ]
        ),
    ]
)
