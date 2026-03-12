// swift-tools-version: 6.2

import PackageDescription

extension String {
    static let pdfHTMLRendering: Self = "PDF HTML Rendering"
    var tests: Self { self + " Tests" }
}

extension Target.Dependency {
    static var pdfHTMLRendering: Self { .target(name: .pdfHTMLRendering) }
}

extension Target.Dependency {
    static var htmlRenderable: Self {
        .product(name: "HTML Renderable", package: "swift-html-rendering")
    }
    static var htmlRendering: Self {
        .product(name: "HTML Rendering", package: "swift-html-rendering")
    }
    static var htmlRenderableTestSupport: Self {
        .product(name: "HTML Renderable Test Support", package: "swift-html-rendering")
    }
    static var pdfRenderingTestSupport: Self {
        .product(name: "PDF Rendering Test Support", package: "swift-pdf-rendering")
    }
    static var pdfRendering: Self {
        .product(name: "PDF Rendering", package: "swift-pdf-rendering")
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
    static var cssStandard: Self {
        .product(name: "CSS Standard", package: "swift-css-standard")
    }
    static var w3cCSS: Self {
        .product(name: "W3C CSS", package: "swift-w3c-css")
    }
    static var iso9899: Self {
        .product(name: "ISO 9899", package: "swift-iso-9899")
    }
    static var iec61966: Self {
        .product(name: "IEC 61966", package: "swift-iec-61966")
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
}

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
        .library(name: .pdfHTMLRendering, targets: [.pdfHTMLRendering]),
        .library(name: "PDF HTML Rendering Test Support", targets: ["PDF HTML Rendering Test Support"]),
    ],
    dependencies: [
        .package(path: "../swift-html-rendering"),
        .package(path: "../swift-pdf-rendering"),
        .package(path: "../swift-copy-on-write"),
        .package(path: "../swift-css"),
        .package(path: "../../swift-standards/swift-html-standard"),
        .package(path: "../../swift-standards/swift-css-standard"),
        .package(path: "../../swift-standards/swift-w3c-css"),
        .package(path: "../../swift-standards/swift-iso-9899"),
        .package(path: "../../swift-standards/swift-rfc-4648"),
        .package(path: "../../swift-standards/swift-iec-61966"),
        .package(path: "../../swift-primitives/swift-layout-primitives"),
        .package(path: "../../swift-primitives/swift-dictionary-primitives"),
        .package(path: "../../swift-primitives/swift-stack-primitives"),
        .package(path: "../../swift-primitives/swift-property-primitives"),
    ],
    targets: [
        .target(
            name: .pdfHTMLRendering,
            dependencies: [
                .htmlRenderable,
                .pdfRendering,
                .copyOnWrite,
                .css,
                .htmlStandard,
                .cssStandard,
                .w3cCSS,
                .iso9899,
                .iec61966,
                .rfc4648,
                .layoutPrimitives,
                .dictionaryPrimitives,
                .stackPrimitives,
                .propertyPrimitives,
            ]
        ),
        .target(
            name: "PDF HTML Rendering Test Support",
            dependencies: [
                .pdfHTMLRendering,
                .htmlRenderableTestSupport,
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
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro, .test].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
