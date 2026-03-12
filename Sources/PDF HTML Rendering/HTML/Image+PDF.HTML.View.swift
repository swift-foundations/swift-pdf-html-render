// Image+PDF.HTML.View.swift
// <img> element transformation - embedded image

import HTML_Renderable
import Dictionary_Primitives
import PDF_Rendering
import RFC_4648
import WHATWG_HTML

extension Image: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Flush any pending inline runs (img is inline-block by default)
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Get src attribute - view.src is a Src type, need to get its rawValue
        guard let srcValue = view.src?.rawValue else {
            // No src - render alt text or nothing
            renderAltText(view: view, context: &context)
            return
        }

        // Parse data URL
        guard let dataURL = DataURL.parse(srcValue) else {
            // Not a data URL - render alt text (external URLs not supported)
            renderAltText(view: view, context: &context)
            return
        }

        // Create ISO_32000.Image from the data
        let pdfImage: ISO_32000.Image
        do {
            switch dataURL.mimeType {
            case "image/jpeg", "image/jpg":
                pdfImage = try ISO_32000.Image(jpeg: dataURL.data)
            case "image/png":
                pdfImage = try ISO_32000.Image(png: dataURL.data)
            default:
                // Unsupported format - render alt text
                renderAltText(view: view, context: &context)
                return
            }
        } catch {
            // Failed to parse image - render alt text
            renderAltText(view: view, context: &context)
            return
        }

        // Calculate display dimensions
        let displaySize = calculateDisplaySize(
            intrinsicWidth: pdfImage.pixelWidth,
            intrinsicHeight: pdfImage.pixelHeight,
            context: &context
        )

        // Check for page break
        context.pdf.checkPageBreak(needing: displaySize.height)

        // Create rectangle for image placement
        let imageRect = PDF.UserSpace.Rectangle(
            x: context.pdf.layoutBox.llx,
            y: context.pdf.layoutBox.lly,
            width: displaySize.width,
            height: displaySize.height
        )

        // Emit the image
        context.pdf.emitImage(pdfImage, in: imageRect)

        // Advance Y position
        context.pdf.advance(displaySize.height)
    }

    /// Render alt text when image cannot be displayed
    private static func renderAltText(
        view: Image,
        context: inout PDF.HTML.Context
    ) {
        if let altValue = view.alt?.rawValue, !altValue.isEmpty {
            // Render alt text as italic gray text
            let savedStyle = context.pdf.style
            context.pdf.style.font = context.pdf.style.font.italic
            context.pdf.style.color = .gray(0.5)

            // Create a text run for the alt text
            let altBytes = [UInt8](winAnsi: "[\(altValue)]", withFallback: true)
            context.pdf.append(inline: PDF.Context.Text.Run(
                bytes: altBytes,
                font: context.pdf.style.font,
                fontSize: context.pdf.style.fontSize,
                color: context.pdf.style.color
            ))
            context.pdf.flushInlineRuns()

            context.pdf.style = savedStyle
        }
    }

    /// Calculate display size based on intrinsic dimensions and CSS properties
    private static func calculateDisplaySize(
        intrinsicWidth: Int,
        intrinsicHeight: Int,
        context: inout PDF.HTML.Context
    ) -> (width: PDF.UserSpace.Width, height: PDF.UserSpace.Height) {
        // Get CSS width/height if specified
        let cssWidth = context.attributes["width"].flatMap { Double($0) }
        let cssHeight = context.attributes["height"].flatMap { Double($0) }

        // Available width constraint
        let availableWidth = context.pdf.layoutBox.width

        // Calculate aspect ratio
        let aspectRatio = Double(intrinsicWidth) / Double(intrinsicHeight)

        let finalWidth: PDF.UserSpace.Width
        let finalHeight: PDF.UserSpace.Height

        if let w = cssWidth, let h = cssHeight {
            // Both specified - use as-is (may distort)
            finalWidth = PDF.UserSpace.Width(w)
            finalHeight = PDF.UserSpace.Height(h)
        } else if let w = cssWidth {
            // Width specified, calculate height from aspect ratio
            finalWidth = PDF.UserSpace.Width(w)
            finalHeight = PDF.UserSpace.Height(w / aspectRatio)
        } else if let h = cssHeight {
            // Height specified, calculate width from aspect ratio
            finalHeight = PDF.UserSpace.Height(h)
            finalWidth = PDF.UserSpace.Width(h * aspectRatio)
        } else {
            // Neither specified - use intrinsic size, constrained to available width
            let intrinsicW = PDF.UserSpace.Width(Double(intrinsicWidth))
            let intrinsicH = PDF.UserSpace.Height(Double(intrinsicHeight))

            if intrinsicW > availableWidth {
                // Scale down to fit available width
                finalWidth = availableWidth
                // Scale factor: Width / Width = dimensionless ratio
                let scale = availableWidth / intrinsicW
                finalHeight = intrinsicH * scale
            } else {
                finalWidth = intrinsicW
                finalHeight = intrinsicH
            }
        }

        // Ensure width doesn't exceed available width
        if finalWidth > availableWidth {
            // Scale factor: Width / Width = dimensionless ratio
            let scale = availableWidth / finalWidth
            return (availableWidth, finalHeight * scale)
        }

        return (finalWidth, finalHeight)
    }
}

// MARK: - Data URL Parser (RFC 2397)

extension Image {
    /// Parsed data URL components
    struct DataURL {
        let mimeType: String
        let data: [UInt8]

        /// Parse a data URL (RFC 2397)
        ///
        /// Format: `data:[<mediatype>][;base64],<data>`
        ///
        /// - Parameter urlString: The data URL string
        /// - Returns: Parsed components, or nil if invalid
        static func parse(_ urlString: String) -> DataURL? {
            // Must start with "data:"
            guard urlString.hasPrefix("data:") else { return nil }

            // Find the comma separator
            guard let commaIndex = urlString.firstIndex(of: ",") else { return nil }

            // Extract metadata and data portions
            let metadataStart = urlString.index(urlString.startIndex, offsetBy: 5)
            let metadata = String(urlString[metadataStart..<commaIndex])
            let dataStart = urlString.index(after: commaIndex)
            let base64String = String(urlString[dataStart...])

            // Parse metadata for MIME type and encoding
            let parts = metadata.split(separator: ";", omittingEmptySubsequences: false)

            // First part is MIME type (default: text/plain)
            let mimeType = parts.first.map(String.init) ?? "text/plain"

            // Check for base64 encoding
            let isBase64 = parts.contains { $0 == "base64" }

            guard isBase64 else {
                // Only base64 encoding is supported for images
                return nil
            }

            // Decode base64 data using RFC 4648
            guard let decoded = RFC_4648.Base64.decode(base64String) else {
                return nil
            }

            return DataURL(mimeType: mimeType, data: decoded)
        }
    }
}
