// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-pdf-html-rendering",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "PDF HTML Rendering", targets: ["PDF HTML Rendering"]),
    ],
    dependencies: [
        .package(path: "../swift-html-rendering"),
        .package(path: "../swift-pdf-rendering"),
        .package(path: "../swift-css"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-html-standard"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-css-standard"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-w3c-css"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-standards"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-iso-9899"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-iec-61966"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
        .package(
            url: "https://github.com/coenttb/swift-html-to-pdf",
            from: "1.0.0",
            traits: ["HTML"]
        ),
    ],
    targets: [
        .target(
            name: "PDF HTML Rendering",
            dependencies: [
                .product(name: "HTML Renderable", package: "swift-html-rendering"),
                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
                .product(name: "CSS", package: "swift-css"),
                .product(name: "HTML Standard", package: "swift-html-standard"),
                .product(name: "CSS Standard", package: "swift-css-standard"),
                .product(name: "W3C CSS", package: "swift-w3c-css"),
                .product(name: "Standards", package: "swift-standards"),
                .product(name: "ISO 9899", package: "swift-iso-9899"),
                .product(name: "IEC 61966", package: "swift-iec-61966"),
            ]
        ),
        .testTarget(
            name: "PDF HTML Rendering Tests",
            dependencies: [
                "PDF HTML Rendering",
                .product(name: "HtmlToPdf", package: "swift-html-to-pdf"),
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "HTML Renderable TestSupport", package: "swift-html-rendering"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
