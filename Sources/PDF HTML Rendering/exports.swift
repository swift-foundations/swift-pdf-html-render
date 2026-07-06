// exports.swift
// Public exports for HTML PDF Rendering Refactor

@_exported import CSS
// MemberImportVisibility: modules used in public extensions.
// These two imports are deliberately `public` WITHOUT `@_exported`: they only
// satisfy MemberImportVisibility for public extensions and must NOT re-export
// the upstream surface into this module's consumers (an @_exported flip on a
// deliberate non-exported import is exactly what broke swift-ascii consumers —
// see the ascii shield precedent, swift-ascii commit f40c3c9). The rule is
// wrong here, not the code; a [RULE-EXEMPT] carve-out escalation to the linter
// arc is pending.
// swiftlint:disable:next exports_swift_strict_shape
public import Dictionary_Primitives
@_exported import HTML_Rendering_Core
@_exported import HTML_Standard
@_exported import PDF_Rendering
// reason: deliberately non-exported (MemberImportVisibility) — see the
// Dictionary_Primitives comment above; ascii f40c3c9 precedent.
// swiftlint:disable:next exports_swift_strict_shape
public import Render_Primitives
