import HTML_Rendering_Core
import Layout_Primitives
public import Ownership_Mutable_Primitives
import PDF_Rendering
import Render_Primitives

extension Render.Context {

    public static func pdfHTML(state: Ownership.Mutable<PDF.HTML.Context>) -> Self {

        func record(_ action: Render.Action) {
            if state.value.speculativeActions != nil {
                state.value.speculativeActions!.append(action)
            }
        }

        func resolveSpeculative(minimumRequired: PDF.UserSpace.Height) {
            guard let snapshot = state.value.speculativeSnapshot,
                let actions = state.value.speculativeActions
            else { return }

            state.value.speculativeSnapshot = nil
            state.value.speculativeActions = nil

            if !state.value.pdf.page.exceeds(adding: minimumRequired) {
                state.value.avoidPageBreakAfter = false
                return
            }

            state.value = snapshot
            state.value.speculativeSnapshot = nil
            state.value.speculativeActions = nil
            state.value.avoidPageBreakAfter = false

            state.value.pdf.flush.inline()
            state.value.pdf.page.new()

            for action in actions {
                state.value.interpret(action)
            }
        }

        return .init(
            text: {
                record(.text($0))
                state.value.text($0)
            },
            break: Render.Break(
                line: {
                    record(.break(.line))
                    state.value.lineBreak()
                },
                thematic: {
                    record(.break(.thematic))
                    state.value.thematicBreak()
                },
                page: {
                    record(.break(.page))
                    state.value.pageBreak()
                }
            ),
            image: {
                record(.image(source: $0, alt: $1))
                state.value.image(source: $0, alt: $1)
            },
            push: Render.Push(
                block: {
                    record(.push(.block(role: $0, style: $1)))
                    PDF.HTML.Context._pushBlock(&state.value, role: $0, style: $1)
                },
                inline: {
                    record(.push(.inline(role: $0, style: $1)))
                    PDF.HTML.Context._pushInline(&state.value, role: $0, style: $1)
                },
                list: {
                    record(.push(.list(kind: $0, start: $1)))
                    PDF.HTML.Context._pushList(&state.value, kind: $0, start: $1)
                },
                item: {
                    record(.push(.item))
                    PDF.HTML.Context._pushItem(&state.value)
                },
                link: {
                    record(.push(.link(destination: $0)))
                    PDF.HTML.Context._pushLink(&state.value, destination: $0)
                },
                attributes: {
                    record(.push(.attributes))
                    PDF.HTML.Context._pushAttributes(&state.value)
                },
                element: { tagName, isBlock, isVoid, isPreElement in
                    if isBlock {
                        let isHeading = HTML.Tag.Element<Never>.headingLevel(for: tagName) != nil

                        if !isHeading && state.value.speculativeSnapshot != nil {
                            let lineHeight = state.value.pdf.style.line.height
                            let marginTop = PDF.UserSpace.Size<1>(
                                HTML.Tag.Element<Never>.blockMargins(
                                    for: tagName,
                                    configuration: state.value.configuration
                                )?.top ?? .length(.em(0)),
                                currentSize: state.value.pdf.style.fontSize,
                                baseFontSize: state.value.configuration.defaultFontSize
                            ).height

                            let minimumFollowingContent = marginTop + lineHeight * 3
                            resolveSpeculative(minimumRequired: minimumFollowingContent)
                        }

                        if isHeading && state.value.speculativeSnapshot == nil {
                            state.value.speculativeSnapshot = state.value
                            state.value.speculativeActions = []
                        }
                    }

                    record(
                        .push(
                            .element(
                                tagName: tagName,
                                isBlock: isBlock,
                                isVoid: isVoid,
                                isPreElement: isPreElement
                            )
                        )
                    )
                    PDF.HTML.Context._pushElement(
                        &state.value,
                        tagName: tagName,
                        isBlock: isBlock,
                        isVoid: isVoid,
                        isPreElement: isPreElement
                    )
                },
                style: {
                    record(.push(.style))
                    PDF.HTML.Context._pushStyle(&state.value)
                }
            ),
            pop: Render.Pop(
                block: {
                    record(.pop(.block))
                    PDF.HTML.Context._popBlock(&state.value)
                },
                inline: {
                    record(.pop(.inline))
                    PDF.HTML.Context._popInline(&state.value)
                },
                list: {
                    record(.pop(.list))
                    PDF.HTML.Context._popList(&state.value)
                },
                item: {
                    record(.pop(.item))
                    PDF.HTML.Context._popItem(&state.value)
                },
                link: {
                    record(.pop(.link))
                    PDF.HTML.Context._popLink(&state.value)
                },
                attributes: {
                    record(.pop(.attributes))
                    PDF.HTML.Context._popAttributes(&state.value)
                },
                element: {
                    record(.pop(.element(isBlock: $0)))
                    PDF.HTML.Context._popElement(&state.value, isBlock: $0)
                },
                style: {
                    record(.pop(.style))
                    PDF.HTML.Context._popStyle(&state.value)
                }
            ),
            setAttribute: {
                record(.attribute(set: $0, value: $1))
                state.value.set(attribute: $0, $1)
            },
            addClass: {
                record(.class(add: $0))
                state.value.add(class: $0)
            },
            writeRaw: {
                record(.raw($0))
                state.value.write(raw: $0)
            },
            registerStyle: {
                record(.style(register: $0, atRule: $1, selector: $2, pseudo: $3))
                return state.value.register(style: $0, atRule: $1, selector: $2, pseudo: $3)
            },
            applyInlineStyle: {
                let handled = state.value.apply(inlineStyle: $0)

                if state.value.avoidPageBreakAfter && state.value.speculativeSnapshot == nil {
                    state.value.speculativeSnapshot = state.value
                    state.value.speculativeActions = []
                }
                return handled
            },
            speculative: Render.Speculative(
                begin: {
                    guard state.value.speculativeSnapshot == nil else { return }
                    state.value.speculativeSnapshot = state.value
                    state.value.speculativeActions = []
                },
                check: { minimumRequired in
                    resolveSpeculative(
                        minimumRequired: PDF.UserSpace.Height(Double(minimumRequired))
                    )
                }
            )
        )
    }
}
