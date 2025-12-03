// picture.swift
// Picture element renderer
import PDF_Rendering
import HTML_Standard
extension Picture {
    /// Renderer for the `<picture>` element.
    ///
    /// The `<picture>` element contains zero or more `<source>` elements
    /// and one `<img>` element to offer alternative versions of an image.
    /// In PDF rendering, this simply renders its child `<img>` element.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        // Picture element is a container that provides fallback images
        // In PDF context, we just render the children (the img element)
        for child in children {
            _ = HTML.renderToPDF(child, configuration: configuration, style: style, context: &context)
        }
    }
}
