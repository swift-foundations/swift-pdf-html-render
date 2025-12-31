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
        .library(name: "PDF HTML Rendering", targets: ["PDF HTML Rendering"])
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/swift-html-rendering", from: "0.1.15"),
        .package(url: "https://github.com/coenttb/swift-pdf-rendering", from: "0.6.0"),
        .package(url: "https://github.com/coenttb/swift-copy-on-write", from: "0.3.1"),
        .package(url: "https://github.com/coenttb/swift-css", from: "0.6.1"),
        .package(url: "https://github.com/swift-standards/swift-html-standard", from: "0.1.6"),
        .package(url: "https://github.com/swift-standards/swift-css-standard", from: "0.1.7"),
        .package(url: "https://github.com/swift-standards/swift-w3c-css", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.21.0"),
        .package(url: "https://github.com/swift-standards/swift-iso-9899", from: "0.2.3"),
        .package(url: "https://github.com/swift-standards/swift-rfc-4648", from: "0.2.1"),
        .package(url: "https://github.com/swift-standards/swift-iec-61966", from: "0.1.3"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.7"),
    ],
    targets: [
        .target(
            name: "PDF HTML Rendering",
            dependencies: [
                .product(name: "HTML Renderable", package: "swift-html-rendering"),
                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
                .product(name: "Copy on Write", package: "swift-copy-on-write"),
                .product(name: "CSS", package: "swift-css"),
                .product(name: "HTML Standard", package: "swift-html-standard"),
                .product(name: "CSS Standard", package: "swift-css-standard"),
                .product(name: "W3C CSS", package: "swift-w3c-css"),
                .product(name: "Standards", package: "swift-standards"),
                .product(name: "ISO 9899", package: "swift-iso-9899"),
                .product(name: "IEC 61966", package: "swift-iec-61966"),
                .product(name: "RFC 4648", package: "swift-rfc-4648"),
            ]
        ),
        .testTarget(
            name: "PDF HTML Rendering Tests",
            dependencies: [
                "PDF HTML Rendering",
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "HTML Rendering TestSupport", package: "swift-html-rendering"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "StandardsTestSupport", package: "swift-standards"),
            ]
        ),
    ]
)
