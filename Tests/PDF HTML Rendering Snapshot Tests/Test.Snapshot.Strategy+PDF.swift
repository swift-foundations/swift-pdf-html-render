//
//  Test.Snapshot.Strategy+PDF.swift
//  swift-pdf-html-rendering
//

import Binary_Serializable_Primitives
import Byte_Primitive
import PDF_Rendering
import Test_Snapshot_Primitives

extension Test.Snapshot.Strategy where Value == PDF.Document, Format == [Byte] {
    static var pdf: Self {
        Test.Snapshot.Strategy<[Byte], [Byte]>(pathExtension: "pdf", diffing: .data)
            .pullback { (doc: PDF.Document) -> [Byte] in [Byte](doc) }
    }
}
