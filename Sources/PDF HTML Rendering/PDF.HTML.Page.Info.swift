// PDF.HTML.Page.Info.swift
// Current page information for header/footer builders

extension PDF.HTML.Page {
    /// Information about the current page, provided to header/footer builders.
    ///
    /// Used during two-pass rendering to provide accurate page numbers and
    /// section information for running headers and footers.
    public struct Info: Sendable {
        /// Current page number (1-indexed)
        public let pageNumber: Int

        /// Total number of pages in the document
        public let totalPages: Int

        /// Title of the current section (from most recent H1-H3 heading)
        public let sectionTitle: String?

        /// Document title (from configuration)
        public let documentTitle: String?

        /// Document date string (from configuration)
        public let date: String?

        public init(
            pageNumber: Int,
            totalPages: Int,
            sectionTitle: String? = nil,
            documentTitle: String? = nil,
            date: String? = nil
        ) {
            self.pageNumber = pageNumber
            self.totalPages = totalPages
            self.sectionTitle = sectionTitle
            self.documentTitle = documentTitle
            self.date = date
        }
    }
}
