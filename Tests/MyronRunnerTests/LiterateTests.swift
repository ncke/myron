import Testing
import Myron
@testable import MyronRunner

// MARK: - Literate

@Suite("Literate")

struct LiterateTests {

    // Documents are written as lines, and the extracted code is compared line by
    // line, so a test states exactly which lines survive and where.
    private static func segments(_ lines: [String]) -> [[String]] {
        Literate.segments(fromMarkdown: lines.joined(separator: "\n")).map { segment in
            segment.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        }
    }

    // The code of a document that never resets its environment.
    private static func code(_ lines: [String]) -> [String] {
        let all = segments(lines)
        #expect(all.count == 1)
        return all.first ?? []
    }

    private static func source(_ lines: [String]) throws -> String {
        try #require(Literate.segments(fromMarkdown: lines.joined(separator: "\n")).first)
    }

    // MARK: Extraction

    @Test("prose and fences become empty lines and code keeps its place")
    func proseBlanked() {
        let document = [
            "# Squares",
            "",
            "```lisp",
            "(define (sq x) (* x x))",
            "```",
            "Some prose.",
        ]
        #expect(Self.code(document) == ["", "", "", "(define (sq x) (* x x))", "", ""])
    }

    @Test("lisp and myron fences both run, in any case", arguments: ["lisp", "myron", "LISP", "Myron"])
    func runnableLanguages(language: String) {
        #expect(Self.code(["```\(language)", "(+ 1 2)", "```"]) == ["", "(+ 1 2)", ""])
    }

    @Test("other languages and bare fences do not run", arguments: ["swift", "scheme", ""])
    func otherLanguages(language: String) {
        #expect(Self.code(["```\(language)", "(+ 1 2)", "```"]) == ["", "", ""])
    }

    @Test("the ignore attribute keeps a lisp block out of the program")
    func ignoreAttribute() {
        #expect(Self.code(["```lisp ignore", "(car 1)", "```"]) == ["", "", ""])
        #expect(Self.code(["```lisp  foo  ignore", "(car 1)", "```"]) == ["", "", ""])
    }

    @Test("other words after the language do not stop a block running")
    func otherAttributes() {
        #expect(Self.code(["```lisp title=\"squares\"", "(+ 1 2)", "```"]) == ["", "(+ 1 2)", ""])
    }

    // MARK: Fences

    @Test("tilde fences work like backtick fences")
    func tildeFences() {
        #expect(Self.code(["~~~lisp", "(+ 1 2)", "~~~"]) == ["", "(+ 1 2)", ""])
    }

    @Test("a longer fence is not closed by a shorter one")
    func longerFence() {
        let document = ["````lisp", "(+ 1 2)", "```", "(+ 3 4)", "````", "prose"]
        #expect(Self.code(document) == ["", "(+ 1 2)", "```", "(+ 3 4)", "", ""])
    }

    @Test("a fence is not closed by the other fence character")
    func mismatchedCloser() {
        #expect(Self.code(["```lisp", "(+ 1 2)", "~~~", "```"]) == ["", "(+ 1 2)", "~~~", ""])
    }

    @Test("a closing fence may not carry an info string")
    func closerWithInfo() {
        #expect(Self.code(["```lisp", "(+ 1 2)", "```lisp", "```"]) == ["", "(+ 1 2)", "```lisp", ""])
    }

    @Test("an unclosed fence runs to the end of the document")
    func unclosedFence() {
        #expect(Self.code(["```lisp", "(+ 1 2)", "(+ 3 4)"]) == ["", "(+ 1 2)", "(+ 3 4)"])
    }

    @Test("a fence may be indented by up to three spaces, but not four")
    func indentedFences() {
        #expect(Self.code(["   ```lisp", "(+ 1 2)", "   ```"]) == ["", "(+ 1 2)", ""])
        #expect(Self.code(["    ```lisp", "(+ 1 2)", "    ```"]) == ["", "", ""])
    }

    @Test("two backticks, or a backtick in the info string, do not open a fence")
    func notFences() {
        #expect(Self.code(["``lisp", "(+ 1 2)", "``"]) == ["", "", ""])
        #expect(Self.code(["```lisp `x`", "(+ 1 2)", "```"]) == ["", "", ""])
    }

    @Test("CRLF line endings are recognised, and every line keeps its number")
    func lineEndings() throws {
        let document = "prose\r\n```lisp\r\n(+ 1 2)\r\n```\r\n"
        let code = try #require(Literate.segments(fromMarkdown: document).first)
        #expect(code == "\n\n(+ 1 2)\n\n")
        #expect(code.filter(\.isNewline).count == document.filter(\.isNewline).count)
    }

    // MARK: Resetting the Environment

    @Test("a reset-environment block starts a new segment")
    func resetStartsSegment() {
        let document = [
            "```lisp",
            "(define x 1)",
            "```",
            "```lisp reset-environment",
            "(define y 2)",
            "```",
            "```lisp",
            "(+ y 1)",
            "```",
        ]
        #expect(Self.segments(document) == [
            ["", "(define x 1)", "", "", "", "", "", "", ""],
            ["", "", "", "", "(define y 2)", "", "", "(+ y 1)", ""],
        ])
    }

    @Test("a reset in the first block leaves an empty first segment")
    func resetFirst() {
        let document = ["```lisp reset-environment", "(+ 1 2)", "```"]
        #expect(Self.segments(document) == [["", "", ""], ["", "(+ 1 2)", ""]])
    }

    @Test("each reset starts another segment")
    func repeatedResets() {
        let document = [
            "```lisp reset-environment", "1", "```",
            "```myron reset-environment", "2", "```",
        ]
        #expect(Self.segments(document).count == 3)
    }

    @Test("an ignored block or another language does not reset")
    func nonRunningBlocksDoNotReset() {
        #expect(Self.segments(["```lisp ignore reset-environment", "1", "```"]).count == 1)
        #expect(Self.segments(["```swift reset-environment", "1", "```"]).count == 1)
    }

    // MARK: Evaluation

    @Test("the extracted code evaluates as a program")
    func evaluates() throws {
        let document = [
            "Define it:",
            "```lisp",
            "(define (sq x) (* x x))",
            "```",
            "Then use it:",
            "```myron",
            "(sq 7)",
            "```",
        ]
        let session = MyronSession()
        #expect(try session.eval(Self.source(document)).asSuccess?.asInteger == 49)
    }

    @Test("an error's location points at its line in the document")
    func errorLocation() throws {
        let document = ["# Oops", "", "```lisp", "(+ 1 1)", "(car 1)", "```"]
        let source = try Self.source(document)

        let error = try #require(MyronSession().eval(source).asFailure?.first)
        let offset = try #require(error.location?.lowerBound)
        let line = source.prefix(offset).filter(\.isNewline).count + 1
        #expect(line == 5)
    }

}
