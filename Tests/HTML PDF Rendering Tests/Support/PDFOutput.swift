// PDFOutput.swift

import Foundation

enum PDFOutput {
    static let directory = "/tmp/swift-pdf-html-rendering"

    static func write(_ bytes: [UInt8], name: String) throws -> String {
        let fm = FileManager.default
        try fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let path = "\(directory)/\(name).pdf"
        try Data(bytes).write(to: URL(fileURLWithPath: path))
        return path
    }
}
