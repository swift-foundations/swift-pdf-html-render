// PDF.HTML.Context+ApplyParsedCSS.swift
// Apply parsed CSS rules at element-push time.
//
// Called from `_pushElement` after UA-level `applyTagStyle` so author-level
// CSS rules override UA defaults per CSS Cascade §6.4 (origin/importance).
// Source-order resolution per CSS Cascade §6.4.4: later rules at the same
// selector win, achieved by each dispatched modifier overwriting context
// state in iteration order.
//
// Phase 1 matching scope:
//   - Type-selector (`html`, `body`, `h1`, etc.)
//   - Universal selector (`*`)
//   - Unsupported selectors (class, ID, attribute, pseudo, combinator)
//     are parsed-but-classified `.unsupported` by the parser and match
//     nothing here.
//
// Phase 1 @media filter (Option C — print-media-aware):
//   - `unconditional` and `printIncludes` → APPLIES
//   - `screenOnly`, `bareFeature`, `other` → SKIPS

import PDF_Rendering

extension PDF.HTML.Context {
    /// Iterate the accumulated parsed stylesheet and dispatch matching
    /// rules' declarations for the given tag name.
    ///
    /// - Parameter tagName: Lowercased tag name of the element being
    ///   pushed (caller MUST lowercase per HTML §3.2.2 case-insensitivity).
    public mutating func applyParsedCSSRules(forTagName tagName: String) {
        for rule in parsedStylesheet.rules {
            // Media-context filter (Option C).
            switch rule.mediaContext {
            case .unconditional, .printIncludes:
                break

            case .screenOnly, .bareFeature, .other:
                continue
            }

            // Selector match: any selector in the rule matches the element.
            let matches = rule.selectors.contains { selector in
                switch selector {
                case .universal:
                    return true

                case .type(let s):
                    return s == tagName

                case .unsupported:
                    return false
                }
            }
            guard matches else { continue }

            // Dispatch each declaration via per-property apply.
            for decl in rule.declarations {
                PDF.HTML.CSS.Apply.apply(
                    declaration: decl,
                    to: &self,
                    configuration: configuration
                )
            }
        }
    }
}
