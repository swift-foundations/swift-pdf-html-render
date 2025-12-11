//
//  File.swift
//  swift-pdf-html-rendering
//
//  Created by Coen ten Thije Boonkkamp on 11/12/2025.
//

public func with<Root, Value>(
    _ root: inout Root,
    _ keyPath: WritableKeyPath<Root, Value>,
    _ body: (inout Value) -> Void
) {
    var value = root[keyPath: keyPath]
    body(&value)
    root[keyPath: keyPath] = value
}

public func with<Root, Value>(
    _ root: inout Root,
    _ keyPath: WritableKeyPath<Root, Value?>,
    _ body: (inout Value) -> Void
) {
    guard var value = root[keyPath: keyPath] else {
        return
    }
    body(&value)
    root[keyPath: keyPath] = value
}
