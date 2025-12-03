// Containers+Transform.swift
// Block container elements: <div>, <section>, <article>, <header>, <footer>, <main>, <nav>, <aside>

import HTML_Standard
import PDF_Rendering

extension ContentDivision: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}

extension Section: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}

extension Article: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}

extension Header: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}

extension Footer: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}

extension Main: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}

extension NavigationSection: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}

extension Aside: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.block(content: content, context: &context, configuration: configuration)
    }
}
