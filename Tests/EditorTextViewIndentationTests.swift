import AppKit
import XCTest
@testable import ItsypadCore

final class EditorTextViewIndentationTests: XCTestCase {
    private var originalIndentUsingSpaces = true
    private var originalTabWidth = 4

    override func setUp() {
        super.setUp()
        originalIndentUsingSpaces = SettingsStore.shared.indentUsingSpaces
        originalTabWidth = SettingsStore.shared.tabWidth
        SettingsStore.shared.indentUsingSpaces = true
        SettingsStore.shared.tabWidth = 4
    }

    override func tearDown() {
        SettingsStore.shared.indentUsingSpaces = originalIndentUsingSpaces
        SettingsStore.shared.tabWidth = originalTabWidth
        super.tearDown()
    }

    func testIndentCurrentLinePreservesCaretOffset() {
        let textView = makeTextView(text: "one\ntwo\nthree", selection: NSRange(location: 6, length: 0))

        textView.indentLines()

        XCTAssertEqual(textView.string, "one\n    two\nthree")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 10, length: 0))
    }

    func testOutdentCurrentLinePreservesCaretOffset() {
        let textView = makeTextView(text: "one\n    two\nthree", selection: NSRange(location: 10, length: 0))

        textView.outdentLines()

        XCTAssertEqual(textView.string, "one\ntwo\nthree")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 6, length: 0))
    }

    func testIndentSelectedLines() {
        let textView = makeTextView(text: "one\ntwo\nthree", selection: NSRange(location: 0, length: 7))

        textView.indentLines()

        XCTAssertEqual(textView.string, "    one\n    two\nthree")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 0, length: 16))
    }

    func testOutdentSelectedLinesWithMixedIndentation() {
        let textView = makeTextView(text: "\tone\n  two\nthree", selection: NSRange(location: 0, length: 11))

        textView.outdentLines()

        XCTAssertEqual(textView.string, "one\ntwo\nthree")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 0, length: 8))
    }

    func testIndentAndOutdentUsingTabs() {
        SettingsStore.shared.indentUsingSpaces = false
        let textView = makeTextView(text: "one", selection: NSRange(location: 2, length: 0))

        textView.indentLines()
        XCTAssertEqual(textView.string, "\tone")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 3, length: 0))

        textView.outdentLines()
        XCTAssertEqual(textView.string, "one")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 2, length: 0))
    }

    func testOutdentUnindentedLineIsNoOp() {
        let textView = makeTextView(text: "one", selection: NSRange(location: 2, length: 0))

        textView.outdentLines()

        XCTAssertEqual(textView.string, "one")
        XCTAssertEqual(textView.selectedRange(), NSRange(location: 2, length: 0))
    }

    private func makeTextView(text: String, selection: NSRange) -> EditorTextView {
        let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        textView.string = text
        textView.setSelectedRange(selection)
        return textView
    }
}
