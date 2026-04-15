# Audit: swift-pdf-html-rendering

## Legacy — Consolidated 2026-04-08

### From: swift-institute/Research/modularization-audit-foundations-batch-B.md (2026-03-20)

**Modularization audit — MOD-001 through MOD-014**

2 products: PDF HTML Rendering, PDF HTML Rendering Test Support.

| Rule | Status | Notes |
|------|--------|-------|
| MOD-001 | N/A | Main + Test Support pattern |
| MOD-002 | N/A | Single main target |
| MOD-003 | N/A | No variant targets |
| MOD-004 | N/A | No ~Copyable concerns |
| MOD-005 | N/A | Single main product |
| MOD-006 | PASS | 10 deps — large count but each serves a distinct rendering concern (HTML, PDF, CSS, base64, layout, dictionary, stack, property) |
| MOD-007 | PASS | Depth 1 |
| MOD-008 | REVIEW | 58 files in single target — moderate size, approaching split consideration |
| MOD-009 | N/A | No inline variants |
| MOD-010 | N/A | No stdlib extensions |
| MOD-011 | PASS | PDF HTML Rendering Test Support published as library product |
| MOD-012 | PASS | Correct L3 naming |
| MOD-013 | N/A | 3 targets, threshold is 5 |
| MOD-014 | N/A | No cross-package optional integration |

**Findings**: 0 FAIL. 1 REVIEW (MOD-008): 58 files is substantial but not at the critical threshold that CSS HTML Rendering's 515 files represents.

---

### From: swift-institute/Research/audits/implementation-naming-2026-03-13/swift-pdf-html-rendering.md (2026-03-13)

#### Scope

- **Target**: swift-pdf-html-rendering (PDF HTML Rendering module)
- **Skills**: implementation, code-surface
- **Files scanned**: 106

#### Findings Summary

| Severity | Count | Primary Rule |
|----------|-------|--------------|
| Critical | 18 | [API-NAME-002] compound identifiers |
| Style | 16 | [IMPL-EXPR-001], [IMPL-031], [IMPL-010], [IMPL-INTENT] |
| **Total** | **34** | |

#### Violations

**[API-NAME-002] Configuration compound properties** (12 instances)
- `Sources/PDF HTML Rendering/PDF.HTML.Configuration.swift:20,36,39,44,47,50,62,65,80,83`
- `paperSize`, `documentTitle`, `documentDate`, `defaultFont`, `defaultFontSize`, `defaultColor`, `paragraphSpacing`, `headingSpacing`, `horizontalGapEm`, `deferredHeaderThreshold`
- Expected: sub-structs (Document, Paragraph, Heading, Header) or drop redundant prefixes

**[API-NAME-002] Compound methods** (6 instances)
- `Sources/PDF HTML Rendering/PDF.HTML.Configuration.swift:185,228,242`
- `Sources/PDF HTML Rendering/HTML.Element.Tag+TagStyle.swift:10,99,131,144,149`
- `resolveLineHeight`, `headingSize`, `headingMarginEm`, `applyTagStyle`, `blockMargins`, `headingLevel`, `isListContainer`, `listType`

**[API-IMPL-005] Multiple types in one file** (2 instances)
- `Sources/PDF HTML Rendering/PDF.HTML.Context.Section.swift` -- Section + ActiveHeading
- `Sources/PDF HTML Rendering/PDF.HTML.Render.Result.swift` -- Render + Result + helpers

**[IMPL-INTENT] Mirror-based type erasure**
- `Sources/PDF HTML Rendering/PDF.HTML.Context+Rendering.swift:165`
- Uses `Mirror(reflecting:)` to unwrap optionals -- should use generic overloads

**[IMPL-EXPR-001] Unnecessary intermediate variables** (2 instances)
- `Sources/PDF HTML Rendering/PDF.Document+HTML.swift:33-56` -- viewer construction
- `Sources/PDF HTML Rendering/PDF.HTML.Context+Rendering.swift:347-358` -- scope in pushElement

**[IMPL-EXPR-001] Repeated `fontSize ?? defaultFontSize` fallback** (12+ files)
- MarginTop, MarginBottom, MarginLeft, MarginRight, PaddingTop, PaddingBottom, PaddingLeft, PaddingRight, Width, Height, Margin, Padding
- Fix: add single `resolvedFontSize` computed property

**[IMPL-031] Manual switch for heading levels** (4 instances)
- `Sources/PDF HTML Rendering/HTML.Element.Tag+TagStyle.swift:13-30,132-140`
- `Sources/PDF HTML Rendering/PDF.HTML.Configuration.swift:229-237,243-251`
- Fix: data-driven lookup from static array

**[IMPL-033]** Per-element loop in cumulative width/height recomputation
- `Sources/PDF HTML Rendering/PDF.HTML.Context.Table.swift:52-59,64-73`

**[IMPL-010] Raw Int** for row/column/level/pageNumber (multiple files)
- `Sources/PDF HTML Rendering/PDF.HTML.Context.Table.swift:83,86,106,...`
- `Sources/PDF HTML Rendering/PDF.HTML.Context.Section.HeadingEntry.swift:7-9`
- `Sources/PDF HTML Rendering/PDF.HTML.Context.Link.Destination.swift:7`
- `Sources/PDF HTML Rendering/PDF.HTML.Page.Info.swift:11-14`

**[IMPL-006]** Untyped `Double` for annotation border width
- `Sources/PDF HTML Rendering/PDF.HTML.Configuration.Annotation.Border.swift:10`

**[IMPL-INTENT] `@unchecked Sendable`** (2 instances)
- `Sources/PDF HTML Rendering/PDF.HTML.Context.Deferred.swift:6`
- `Sources/PDF HTML Rendering/PDF.HTML.Context.Table.Recording.Command.swift:12`

#### Clean Areas

[API-NAME-001], [API-NAME-003], [API-NAME-004], [PATTERN-009], [PATTERN-017], [IMPL-020] -- all PASS. File organization follows one-type-per-file well (2 exceptions noted).

---

### From: swift-institute/Research/pdf-html-rendering-audit.md (2026-03-12, SUPERSEDED by swift-pdf-stack-audit.md)

**Skill**: implementation, naming, code-organization, design — [API-IMPL-005], [IMPL-INTENT], [API-LAYER-002], [PATTERN-013], [API-NAME-002]

**FOUNDATIONAL findings** (5):

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| F-1 | FOUNDATIONAL | Two parallel rendering paths (static + dynamic) duplicate all logic -- ~780 lines of near-identical rendering. Root cause: paths parameterize on one axis of variation (child content rendering). | OPEN -- Highest impact fix |
| F-2 | FOUNDATIONAL | Style save/restore pattern duplicated 3 times (11 properties each, ~66 lines total). Extract `withSavedStyleState` infrastructure. | OPEN |
| F-3 | FOUNDATIONAL | `PDF.HTML.swift` is a 1206-line god-file with 15+ declarations. Violates [API-IMPL-005] at least 10 times. | OPEN |
| F-4 | FOUNDATIONAL | `HTML.Element+PDF.HTML.View.swift` is a 2038-line god-file with both static and dynamic rendering for all tag elements. | OPEN -- Depends on F-1 |
| F-5 | FOUNDATIONAL | 4 nearly identical entry point functions repeat ~20 lines each. Differ by one line. Extract `prepareContext`/`finalizeRendering`. | OPEN |

**STRUCTURAL findings** (6):

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| S-1 | STRUCTURAL | Context is a god object with 15+ fields spanning 6 concerns. | OPEN -- Lower priority than F-1 through F-5 |
| S-2 | STRUCTURAL | 19 protocols, some redundant. 4 table protocols are dead code. | OPEN |
| S-3 | STRUCTURAL | Compound identifiers throughout. Public: `renderBlock`, `renderInline`, `applyCollapsedMargin`, `PDFTextExtractable`. | OPEN |
| S-4 | STRUCTURAL | Duplicated `with` utility -- free functions unused, instance methods used ~30 times. | OPEN |
| S-5 | STRUCTURAL | `PDFTextExtractable` at module scope with compound name. Should be `PDF.HTML.TextExtractable`. | OPEN |
| S-6 | STRUCTURAL | Break flags as mutable state instead of return values (set-check-reset pattern). | OPEN |

**Recommended sequence**: 1. Entry point setup (F-5), 2. `withSavedState` (F-2), 3. Unify rendering paths (F-1), 4. Decompose PDF.HTML.swift (F-3), 5. Decompose tag file (F-4).

---

### From: swift-institute/Research/rendering-packages-naming-implementation-audit.md (2026-03-12, SUPERSEDED)

**Skill**: naming, implementation — [API-NAME-001], [API-NAME-002], [IMPL-INTENT]

| # | Severity | Rule | Finding | Status |
|---|----------|------|---------|--------|
| H-001 | HIGH | [API-IMPL-005] | Configuration.swift contains 16 type declarations in 650 lines. | OPEN |
| H-002 | HIGH | [API-IMPL-005] | Context.Table.swift contains 15 type declarations in 487 lines. | OPEN |
| H-003 | HIGH | [API-IMPL-005] | DynamicDispatchProtocols.swift contains 5 protocol declarations. | OPEN |
| H-004 | HIGH | [API-IMPL-005] | Context.swift contains 9 type declarations in 317 lines. | OPEN |
| H-005 | HIGH | [API-NAME-001] | `HTMLContextStyleModifier` quad-compound protocol name. 45 conformances. | OPEN |
| H-006..H-010 | HIGH | [API-NAME-001] | `SpanGrid`, `CellSpan`, `PendingCellBorder`, `DeferredSpanningCell`, `HeaderState` -- compound type names. | OPEN |
| H-011 | HIGH | [API-NAME-001] | `PageInfo` compound type name. | OPEN |
| H-012 | HIGH | [API-NAME-001] | `TextRun` compound type name. Pervasive in rendering pipeline. | OPEN |

108 total findings: 0 critical, 12 high, 41 medium, 55 low. Dominant theme: compound identifiers (71 of 108).
