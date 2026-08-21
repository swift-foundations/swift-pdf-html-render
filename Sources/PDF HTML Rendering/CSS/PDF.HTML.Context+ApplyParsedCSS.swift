import PDF_Rendering

extension PDF.HTML.Context {

    public mutating func applyParsedCSSRules(forTagName tagName: String) {
        for rule in parsedStylesheet.rules {

            switch rule.mediaContext {
            case .unconditional, .printIncludes:
                break

            case .screenOnly, .bareFeature, .other:
                continue
            }

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
