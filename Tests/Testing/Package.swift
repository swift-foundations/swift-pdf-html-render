// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "testing",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../swift-html-rendering"),
        .package(path: "../../../swift-pdf-rendering"),
        .package(path: "../../../swift-testing"),
    ],
    targets: [
        .testTarget(
            name: "PDF HTML Rendering Performance Tests",
            dependencies: [
                .product(name: "PDF HTML Rendering", package: "swift-pdf-html-rendering"),
                .product(name: "HTML Rendering", package: "swift-html-rendering"),
                .product(name: "PDF Rendering", package: "swift-pdf-rendering"),
                .product(name: "Testing", package: "swift-testing"),
            ]
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
