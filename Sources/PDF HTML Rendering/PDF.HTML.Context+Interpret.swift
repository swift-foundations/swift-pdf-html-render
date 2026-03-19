import Rendering_Primitives

extension PDF.HTML.Context {
    /// Replays a single rendering action through the PDF backend.
    ///
    /// Used by speculative rendering to replay recorded actions after
    /// a rollback (page break due to keep-with-next).
    public mutating func interpret(_ action: Rendering.Action) {
        switch action {
        case .text(let content): text(content)
        case .break(let kind):
            switch kind {
            case .line: lineBreak()
            case .thematic: thematicBreak()
            case .page: pageBreak()
            }
        case .image(let source, let alt): image(source: source, alt: alt)
        case .attribute(let name, let value): set(attribute: name, value)
        case .class(let name): add(class: name)
        case .raw(let bytes): write(raw: bytes)
        case .style(let declaration, let atRule, let selector, let pseudo):
            _ = register(style: declaration, atRule: atRule, selector: selector, pseudo: pseudo)
        case .push(let push):
            switch push {
            case .block(let role, let style):
                Self._pushBlock(&self, role: role, style: style)
            case .inline(let role, let style):
                Self._pushInline(&self, role: role, style: style)
            case .list(let kind, let start):
                Self._pushList(&self, kind: kind, start: start)
            case .item:
                Self._pushItem(&self)
            case .link(let destination):
                Self._pushLink(&self, destination: destination)
            case .attributes:
                Self._pushAttributes(&self)
            case .element(let tagName, let isBlock, let isVoid, let isPreElement):
                Self._pushElement(&self, tagName: tagName, isBlock: isBlock, isVoid: isVoid, isPreElement: isPreElement)
            case .style:
                Self._pushStyle(&self)
            }
        case .pop(let pop):
            switch pop {
            case .block: Self._popBlock(&self)
            case .inline: Self._popInline(&self)
            case .list: Self._popList(&self)
            case .item: Self._popItem(&self)
            case .link: Self._popLink(&self)
            case .attributes: Self._popAttributes(&self)
            case .element(let isBlock): Self._popElement(&self, isBlock: isBlock)
            case .style: Self._popStyle(&self)
            }
        }
    }
}
