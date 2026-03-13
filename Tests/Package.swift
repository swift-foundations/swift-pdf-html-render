// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "testing",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(path: ".."),
        .package(path: "../../swift-testing"),
        .package(path: "../../swift-tests"),
        .package(path: "../../swift-html-rendering"),
        .package(path: "../../swift-pdf-rendering"),
        .package(path: "../../../swift-primitives/swift-test-primitives"),
    ],
    targets: [
        .testTarget(
            name: "PDF HTML Rendering Performance Tests",
            dependencies: [
                .product(name: "PDF HTML Rendering", package: "swift-pdf-html-rendering"),
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "PDF HTML Rendering Performance Tests"
        ),
        .testTarget(
            name: "PDF HTML Rendering Snapshot Tests",
            dependencies: [
                .product(name: "PDF HTML Rendering", package: "swift-pdf-html-rendering"),
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Tests Inline Snapshot", package: "swift-tests"),
                .product(name: "Test Snapshot Primitives", package: "swift-test-primitives"),
                .product(name: "Test Primitives Test Support", package: "swift-test-primitives"),
            ],
            path: "PDF HTML Rendering Snapshot Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
