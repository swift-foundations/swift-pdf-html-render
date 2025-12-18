// InlineQuotation+PDF.HTML.View.swift
// <q> element transformation - inline quotation
// Note: Actual quote rendering happens in HTML.Element._render for "q" tag

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

// InlineQuotation rendering is handled by HTML.Element._render switch case for "q" tag.
// The quotes are inserted around the content there.
