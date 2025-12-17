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
        .package(url: "https://github.com/coenttb/swift-html-rendering", from: "0.1.6"),
        .package(url: "https://github.com/coenttb/swift-pdf-rendering", from: "0.4.0"),
        .package(url: "https://github.com/coenttb/swift-css", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-html-standard", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-css-standard", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-w3c-css", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.14.1"),
        .package(url: "https://github.com/swift-standards/swift-iso-9899", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-iec-61966", from: "0.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
//        .package(
//            url: "https://github.com/coenttb/swift-html-to-pdf",
//            from: "1.0.0",
//            traits: ["HTML"]
//        ),
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
//                .product(name: "HtmlToPdf", package: "swift-html-to-pdf"),
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "HTML Rendering TestSupport", package: "swift-html-rendering"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
