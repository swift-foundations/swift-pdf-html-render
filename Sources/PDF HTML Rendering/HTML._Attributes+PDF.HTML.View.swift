// HTML._Attributes+PDF.HTML.View.swift
// PDF rendering support for HTML._Attributes wrapper

import HTML_Renderable
import Dictionary_Primitives
import PDF_Rendering

extension HTML._Attributes: PDF.HTML.View where Content: PDF.HTML.View {
         public static func _render(
             _ view: Self,
             context: inout PDF.HTML.Context
         ) {
             // Save previous attributes
             let previousAttributes = context.attributes
             defer { context.attributes = previousAttributes }
                                                                                                                      
             // Flatten nested _Attributes by iteratively unwrapping via Mirror.
             // This avoids building up deeply nested generic types like:
             //   _Attributes<_Attributes<_Attributes<_Attributes<...>>>>
             // which crash Swift's runtime during generic metadata instantiation.
                                                                                                                      
             var current: Any = view
             var collectedAttributes: [[String: String]] = []
                                                                                                                      
             while true {
                 let mirror = Mirror(reflecting: current)
                                                                                                                      
                 // Check if this is an _Attributes type (has "content" + "attributes" fields)
                 var contentValue: Any? = nil
                 var attributesValue: [String: String]? = nil
                                                                                                                      
                 for child in mirror.children {
                     if child.label == "content" {
                         contentValue = child.value
                     }
                     if child.label == "attributes", let attrs = child.value as? [String: String] {
                         attributesValue = attrs
                     }
                 }
                                                                                                                      
                 if let attrs = attributesValue {
                     collectedAttributes.append(attrs)
                 }
                                                                                                                      
                 if let content = contentValue {
                     // Check if content is ALSO an _Attributes (nested)
                     let contentMirror = Mirror(reflecting: content)
                     var hasContent = false
                     var hasAttributes = false
                     for child in contentMirror.children {
                         if child.label == "content" { hasContent = true }
                         if child.label == "attributes" { hasAttributes = true }
                     }
                                                                                                                      
                     if hasContent && hasAttributes {
                         // Content is another _Attributes - continue unwrapping
                         current = content
                         continue
                     } else {
                         // Content is the actual view - render it
                         // Merge all collected attributes (earlier first, later override)
                         for attrs in collectedAttributes {
                             context.attributes.merge.keep.last(attrs.lazy.map { ($0.key, $0.value) })
                         }
                                                                                                                      
                         // Use dynamic dispatch to render the inner content
                         PDF.HTML.renderInnerContent(content, context: &context)
                         return
                     }
                 } else {
                     // No content field - shouldn't happen for valid _Attributes
                     break
                 }
             }
         }
     }   
