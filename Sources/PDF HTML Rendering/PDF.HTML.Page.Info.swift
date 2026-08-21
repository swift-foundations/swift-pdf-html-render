extension PDF.HTML.Page {

    public struct Info: Sendable {

        public let pageNumber: Int

        public let totalPages: Int

        public let sectionTitle: String?

        public let documentTitle: String?

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
