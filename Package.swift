// swift-tools-version:6.2

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
        .package(path: "../swift-css"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-html-standard"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-css-standard"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-w3c-css"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-standards"),
        .package(path: "/Users/coen/Developer/swift-standards/swift-iso-9899"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
//        .package(
//            url: "https://github.com/coenttb/swift-html-to-pdf",
//            from: "1.0.0",
//            traits: ["HTML"]
//        ),
    ],
    targets: [
        // Temporarily disabled - needs API update
        .target(
            name: "HTML PDF Rendering",
            dependencies: [
                .product(name: "HTML Renderable", package: "swift-html-rendering"),
                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
                .product(name: "CSS", package: "swift-css"),
                .product(name: "HTML Standard", package: "swift-html-standard"),
                .product(name: "CSS Standard", package: "swift-css-standard"),
                .product(name: "W3C CSS", package: "swift-w3c-css"),
                .product(name: "Standards", package: "swift-standards"),
                .product(name: "ISO 9899", package: "swift-iso-9899"),
            ]
        ),
//        .target(
//            name: "HTML PDF Rendering Refactor",
//            dependencies: [
//                .product(name: "HTML Renderable", package: "swift-html-rendering"),
//                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
//                .product(name: "CSS", package: "swift-css"),
//                .product(name: "HTML Standard", package: "swift-html-standard"),
//                .product(name: "CSS Standard", package: "swift-css-standard"),
//                .product(name: "W3C CSS", package: "swift-w3c-css"),
//                .product(name: "Standards", package: "swift-standards"),
//                .product(name: "ISO 9899", package: "swift-iso-9899"),
//            ]
//        ),
        // Temporarily disabled - needs API update
        .testTarget(
            name: "HTML PDF Rendering Tests",
            dependencies: [
                "HTML PDF Rendering",
//                .product(name: "HtmlToPdf", package: "swift-html-to-pdf"),
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "HTML Renderable TestSupport", package: "swift-html-rendering"),
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
//        .testTarget(
//            name: "HTML PDF Rendering Refactor Tests",
//            dependencies: [
//                "HTML PDF Rendering Refactor",
//                .product(name: "HTML Rendering", package: "swift-html-rendering"),
//            ]
//        ),
    ]
)
