// swift-tools-version: 6.3.1

import PackageDescription

extension String {
    static let pdfHTMLRendering: Self = "PDF HTML Rendering"
    var tests: Self { self + " Tests" }
}

extension Target.Dependency {
    static var pdfHTMLRendering: Self { .target(name: .pdfHTMLRendering) }
}

extension Target.Dependency {
    static var htmlRenderingCore: Self {
        .product(name: "HTML Rendering Core", package: "swift-html-render")
    }
    static var htmlRendering: Self {
        .product(name: "HTML Rendering", package: "swift-html-render")
    }
    static var htmlRenderingCoreTestSupport: Self {
        .product(name: "HTML Rendering Core Test Support", package: "swift-html-render")
    }
    static var pdfRenderingTestSupport: Self {
        .product(name: "PDF Rendering Test Support", package: "swift-pdf-render")
    }
    static var pdfRendering: Self {
        .product(name: "PDF Rendering", package: "swift-pdf-render")
    }
    static var copyOnWrite: Self {
        .product(name: "Copy on Write", package: "swift-copy-on-write")
    }
    static var css: Self {
        .product(name: "CSS", package: "swift-css")
    }
    static var htmlStandard: Self {
        .product(name: "HTML Standard", package: "swift-html-standard")
    }
    static var rfc4648: Self {
        .product(name: "RFC 4648", package: "swift-rfc-4648")
    }
    static var layoutPrimitives: Self {
        .product(name: "Layout Primitives", package: "swift-layout-primitives")
    }
    static var dictionaryPrimitives: Self {
        .product(name: "Dictionary Primitives", package: "swift-dictionary-primitives")
    }
    static var stackPrimitives: Self {
        .product(name: "Stack Primitives", package: "swift-stack-primitives")
    }
    static var propertyPrimitives: Self {
        .product(name: "Property Primitives", package: "swift-property-primitives")
    }
    static var standardLibraryExtensions: Self {
        .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions")
    }
    static var ownershipMutablePrimitives: Self {
        .product(name: "Ownership Mutable Primitives", package: "swift-ownership-primitives")
    }
    static var sharedPrimitive: Self {
        .product(name: "Shared Primitive", package: "swift-shared-primitives")
    }
    static var hashIndexedPrimitive: Self {
        .product(name: "Hash Indexed Primitive", package: "swift-hash-table-primitives")
    }
    static var hashPrimitives: Self {
        .product(name: "Hash Primitives", package: "swift-hash-primitives")
    }
    static var columnPrimitives: Self {
        .product(name: "Column Primitives", package: "swift-column-primitives")
    }
    static var bufferLinearPrimitive: Self {
        .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives")
    }
    static var dictionaryOrderedPrimitive: Self {
        .product(name: "Dictionary Ordered Primitive", package: "swift-dictionary-ordered-primitives")
    }
    static var bytePrimitives: Self {
        .product(name: "Byte Primitives", package: "swift-byte-primitives")
    }
}

let package = Package(
    name: "swift-pdf-html-render",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: .pdfHTMLRendering, targets: [.pdfHTMLRendering]),
        .library(name: "PDF HTML Rendering Test Support", targets: ["PDF HTML Rendering Test Support"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-html-render.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-pdf-render.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-copy-on-write.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-css.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-html-standard.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-4648.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-layout-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-dictionary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-dictionary-ordered-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-stack-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ownership-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-shared-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-hash-table-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-hash-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-column-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-linear-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-byte-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: .pdfHTMLRendering,
            dependencies: [
                .htmlRenderingCore,
                .pdfRendering,
                .copyOnWrite,
                .css,
                .htmlStandard,
                .rfc4648,
                .layoutPrimitives,
                .dictionaryPrimitives,
                .product(name: "Dictionary Ordered Primitives", package: "swift-dictionary-ordered-primitives"),
                .dictionaryOrderedPrimitive,
                .bytePrimitives,
                .stackPrimitives,
                .propertyPrimitives,
                .standardLibraryExtensions,
                .ownershipMutablePrimitives,
                .sharedPrimitive,
                .hashIndexedPrimitive,
                .hashPrimitives,
                .columnPrimitives,
                .bufferLinearPrimitive,
            ]
        ),
        .target(
            name: "PDF HTML Rendering Test Support",
            dependencies: [
                .pdfHTMLRendering,
                .htmlRenderingCoreTestSupport,
                .pdfRenderingTestSupport,
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: .pdfHTMLRendering.tests,
            dependencies: [
                .pdfHTMLRendering,
                .htmlRendering,
                "PDF HTML Rendering Test Support",
            ],
            path: "Tests/PDF HTML Rendering Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
