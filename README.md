# swift-pdf-html-render

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Renders HTML content into paginated PDF documents, applying CSS styling, page layout, tables, hyperlinks, and outline bookmarks derived from headings.

---

## Key Features

- **HTML DSL input** — render result-builder HTML (`H1`, `Table`, `UnorderedList`, …) directly to PDF, with no headless browser or WebKit round-trip.
- **CSS styling** — a W3C CSS subset (box model, fonts, text, backgrounds, lists, paged-media, and multi-column properties) maps onto PDF layout, including inline `<style>` stylesheet parsing.
- **Outline bookmarks** — `generateOutline: true` builds a PDF outline from `H1`–`H6` headings.
- **Running headers and footers** — two-pass rendering supplies accurate "Page X of Y" numbering and per-page section titles.
- **Internal links and named destinations** — in-document anchors resolve to PDF link annotations.
- **Tables** — row- and column-spanning grid layout with configurable borders.
- **Viewer preferences and metadata** — set PDF viewer preferences and document info such as title and author.

---

## Quick Start

```swift
import PDF_HTML_Rendering
import HTML_Rendering

// Author the page with the HTML DSL and render directly to PDF bytes —
// no headless browser or WebKit round-trip.
let document = PDF.Document(generateOutline: true) {
    H1 { "Q2 Engineering Report" }
    Paragraph {
        "Throughput rose "
        StrongImportance { "18%" }
        " quarter over quarter."
    }
    H2 { "Highlights" }
    UnorderedList {
        ListItem { "p99 latency down to 2.3 ms" }
        ListItem { "Steady-state memory held at 35 MB" }
    }
}

let bytes = [UInt8](document)   // a complete PDF file, ready to write to disk
```

The HTML element vocabulary (`H1`, `Paragraph`, `Table`, …) comes from the `HTML Rendering` product of [swift-html-render](https://github.com/swift-foundations/swift-html-render); add it alongside this package (see Installation).

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-pdf-html-render.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "PDF HTML Rendering", package: "swift-pdf-html-render")
    ]
)
```

Authoring HTML uses the element DSL from swift-html-render, so add its `HTML Rendering` product to the same target:

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-pdf-html-render.git", branch: "main"),
    .package(url: "https://github.com/swift-foundations/swift-html-render.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "PDF HTML Rendering", package: "swift-pdf-html-render"),
        .product(name: "HTML Rendering", package: "swift-html-render")
    ]
)
```

Requires Swift 6.3.1 and the macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 SDKs (or later).

---

## Architecture

| Product | Import | When to import |
|---------|--------|----------------|
| `PDF HTML Rendering` | `PDF_HTML_Rendering` | Application code that renders HTML to PDF. |
| `PDF HTML Rendering Test Support` | `PDF_HTML_Rendering_Test_Support` | Test targets that assert on or snapshot rendered PDF output. |

Importing `PDF_HTML_Rendering` re-exports the PDF rendering and HTML rendering-core surfaces it builds on, so `PDF.Document`, `HTML.View`, and CSS types are available without additional imports.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public release.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
