// ConditionalTableTests.swift
// Tests for conditional content inside table elements

import Foundation
import Testing
import HTML_Rendering
import PDF_Rendering
@testable import PDF_HTML_Rendering

@Suite
struct `Conditional Table Tests` {

    /// Test conditional row inside TableBody (crashes without Mirror-based detection)
    @Test
    func `Conditional TableRow inside TableBody`() {
        struct TestTable: HTML.View {
            let showExtraRow = true
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell { "Always shown" }
                        }
                        if showExtraRow {
                            TableRow {
                                TableDataCell { "Conditionally shown" }
                            }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document { TestTable() }
        }
        let _ = [UInt8](document)
    }

    /// Test conditional content inside TableDataCell
    @Test
    func `Conditional content inside TableDataCell`() {
        struct TestTable: HTML.View {
            let useAlternateText = true
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell {
                                if useAlternateText {
                                    "Option A"
                                } else {
                                    "Option B"
                                }
                            }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document { TestTable() }
        }
        let _ = [UInt8](document)
    }

    /// Test conditional row with styled content inside TableBody (mimics Checklist crash)
    /// This more closely matches the structure in Checklist.swift where StrongImportance
    /// (a styled element) is used inside conditional table cells.
    @Test
    func `Conditional TableRow with styled content inside TableBody`() {
        struct TestChecklist: HTML.View {
            let showSCorpRow = true
            var body: some HTML.View {
                Table {
                    TableHead {
                        TableRow {
                            TableHeader { "☐" }
                            TableHeader { "Task" }
                            TableHeader { "Fee" }
                            TableHeader { "Deadline" }
                            TableHeader { "Notes" }
                        }
                    }
                    TableBody {
                        TableRow {
                            TableDataCell { "☐" }
                            TableDataCell {
                                StrongImportance { "Apply for EIN (Form SS-4)" }
                            }
                            TableDataCell { "Free" }
                            TableDataCell { "Before banking" }
                            TableDataCell { "Apply online at www.irs.gov" }
                        }
                        if showSCorpRow {
                            TableRow {
                                TableDataCell { "☐" }
                                TableDataCell {
                                    StrongImportance { "File Form 2553 (S-Corp Election)" }
                                }
                                TableDataCell { "Free" }
                                TableDataCell { "Within 75 days" }
                                TableDataCell { "All shareholders must consent" }
                            }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document { TestChecklist() }
        }
        let _ = [UInt8](document)
    }

    /// Test conditional content with styled wrapper inside TableDataCell
    @Test
    func `Conditional styled content inside TableDataCell`() {
        struct TestTable: HTML.View {
            let isSCorp = true
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell {
                                StrongImportance { "Federal Tax Return" }
                            }
                            TableDataCell { "Annually" }
                            TableDataCell { "Varies" }
                            TableDataCell {
                                if isSCorp {
                                    "Form 1120-S (S-Corp)"
                                } else {
                                    "Form 1120 (C-Corp)"
                                }
                            }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document { TestTable() }
        }
        let _ = [UInt8](document)
    }

    /// Test multiple consecutive conditional sections (stress test)
    @Test
    func `Multiple conditional sections in table`() {
        struct TestTable: HTML.View {
            let showSection1 = true
            let showSection2 = false
            let showSection3 = true
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell { "Header" }
                        }
                        if showSection1 {
                            TableRow {
                                TableDataCell {
                                    StrongImportance { "Section 1" }
                                }
                            }
                        }
                        if showSection2 {
                            TableRow {
                                TableDataCell {
                                    Emphasis { "Section 2" }
                                }
                            }
                        }
                        if showSection3 {
                            TableRow {
                                TableDataCell {
                                    StrongImportance { "Section 3" }
                                }
                            }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document { TestTable() }
        }
        let _ = [UInt8](document)
    }

    /// Test Optional (if without else) inside TableBody - this creates Optional<TableRow<...>>
    /// which is different from _Conditional and needs separate Mirror-based handling.
    @Test
    func `Optional TableRow inside TableBody (if without else)`() {
        struct TestChecklist: HTML.View {
            let showSCorpRow = true
            var body: some HTML.View {
                Table {
                    TableHead {
                        TableRow {
                            TableHeader { "Task" }
                            TableHeader { "Fee" }
                            TableHeader { "Deadline" }
                        }
                    }
                    TableBody {
                        TableRow {
                            TableDataCell {
                                StrongImportance { "Apply for EIN" }
                            }
                            TableDataCell { "Free" }
                            TableDataCell { "Before banking" }
                        }
                        // This is an 'if' WITHOUT 'else' - creates Optional<TableRow<...>>
                        if showSCorpRow {
                            TableRow {
                                TableDataCell {
                                    StrongImportance { "File Form 2553 (S-Corp Election)" }
                                }
                                TableDataCell { "Free" }
                                TableDataCell { "Within 75 days" }
                            }
                        }
                        TableRow {
                            TableDataCell {
                                StrongImportance { "Open Business Bank Account" }
                            }
                            TableDataCell { "Varies" }
                            TableDataCell { "After EIN" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document { TestChecklist() }
        }
        let _ = [UInt8](document)
    }

    /// Test Optional with false condition (nil case)
    @Test
    func `Optional TableRow with false condition (nil case)`() {
        struct TestTable: HTML.View {
            let showOptionalRow = false
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell { "Always shown" }
                        }
                        if showOptionalRow {
                            TableRow {
                                TableDataCell {
                                    StrongImportance { "This should not appear" }
                                }
                            }
                        }
                        TableRow {
                            TableDataCell { "Also always shown" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document { TestTable() }
        }
        let _ = [UInt8](document)
    }
}
