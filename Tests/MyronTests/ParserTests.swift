import Testing
@testable import Myron

// MARK: - Parser

@Suite("Parser")

struct ParserTests {

    private static func parse(_ source: String) -> ([Expression], [MyronError]) {
        let (tokens, lexerErrors) = Lexer(input: source, sourceHandle: nil).tokenize()
        #expect(lexerErrors.isEmpty, "\(source) did not lex cleanly")
        return Parser(tokens: tokens).parse()
    }

    private static func forms(_ source: String) -> [Expression] {
        let (forms, errors) = parse(source)
        #expect(errors.isEmpty, "\(source) got parser errors \(errors.map(\.reason))")
        return forms
    }

    private static func rendered(_ source: String) -> String {
        return forms(source).map { form in "\(form)" }.joined(separator: " ")
    }

    private static func span(_ expression: Expression?) -> String {
        guard let location = expression?.location else { return "nil" }
        return "\(location.lowerBound)..<\(location.upperBound)"
    }

    // MARK: Top-Level Forms

    @Test("every top-level form is produced", arguments: [
        ("1", 1), ("1 2", 2), ("1 2 3", 3),
        ("'1", 1), ("'1 '2", 2), ("'1 '2 '3", 3),
        ("'1 2", 2), ("1 '2", 2),
        ("''1", 1), ("''1 2", 2), ("2 ''1", 2),
        ("'''1 '''2", 2),
        ("(a) (b)", 2), ("'(a) '(b)", 2), ("'(a) (b)", 2), ("(a) '(b)", 2),
        ("()", 1), ("() ()", 2)
    ] as [(source: String, count: Int)])
    func topLevelFormCount(_ c: (source: String, count: Int)) {
        let forms = Self.forms(c.source)
        #expect(
            forms.count == c.count,
            "\(c.source) gave \(forms.count) forms \(forms.map { "\($0)" }) (expected \(c.count))")
    }

    @Test("a quotation is expanded in place", arguments: [
        ("'1", "(quote 1)"),
        ("'1 '2", "(quote 1) (quote 2)"),
        ("'1 2", "(quote 1) 2"),
        ("''1", "(quote (quote 1))"),
        ("''1 2", "(quote (quote 1)) 2"),
        ("'(a)", "(quote (a))"),
        ("'()", "(quote ())"),
        ("(a '1 b)", "(a (quote 1) b)"),
        ("(a ''b c)", "(a (quote (quote b)) c)"),
        ("('a 'b)", "((quote a) (quote b))")
    ] as [ValueCase])
    func quotationShape(_ c: ValueCase) {
        #expect(
            Self.rendered(c.source) == c.expected,
            "\(c.source) gave \(Self.rendered(c.source)) (expected \(c.expected))")
    }

    // MARK: Locations

    @Test("a list spans from its own bracket to its close", arguments: [
        "(a)", "(a b)", "(a (b) c)", "(a (b (c)) d)", "((a) (b))", "()",
        "(a (b) (c) d)", "((((a))))"
    ])
    func listSpansItself(_ source: String) {
        let outer = Self.forms(source).first
        #expect(
            Self.span(outer) == "0..<\(source.count)",
            "\(source) spans \(Self.span(outer)) (expected 0..<\(source.count))")
    }

    @Test("a quotation spans the tick and its expression", arguments: [
        "'1", "'a", "'()", "'(a)", "'(a (b))", "''1", "'''1"
    ])
    func quotationSpansItself(_ source: String) {
        let quotation = Self.forms(source).first
        #expect(
            Self.span(quotation) == "0..<\(source.count)",
            "\(source) spans \(Self.span(quotation)) (expected 0..<\(source.count))")
    }

    @Test("an inner form keeps its own span")
    func innerSpans() {
        // 0123456789
        // (a (b) c)
        let elements = Self.forms("(a (b) c)").first?.asList()
        #expect(Self.span(elements?[0]) == "1..<2")
        #expect(Self.span(elements?[1]) == "3..<6")
        #expect(Self.span(elements?[2]) == "7..<8")
    }

    // MARK: Errors

    @Test("an unterminated list is reported at the bracket that was not closed", arguments: [
        (source: "(1 2", location: 0..<1),
        (source: "((1)", location: 0..<1),
        (source: "(a (b c", location: 3..<4),
        (source: "(", location: 0..<1)
    ])
    func unterminatedList(_ c: (source: String, location: MyronLocation)) {
        let (forms, errors) = Self.parse(c.source)
        #expect(errors.map(\.reason) == [.expectedRightBracket])
        #expect(
            errors.first?.location == c.location,
            "\(c.source) reported at \(String(describing: errors.first?.location))")
        #expect(forms.isEmpty, "\(c.source) produced a partial form")
    }

    @Test("a surplus bracket is reported where it appears", arguments: [
        (source: ")", location: 0..<1),
        (source: "(a))", location: 3..<4)
    ])
    func unmatchedBracket(_ c: (source: String, location: MyronLocation)) {
        let (_, errors) = Self.parse(c.source)
        #expect(errors.map(\.reason) == [.unmatchedParenthesis])
        #expect(
            errors.first?.location == c.location,
            "\(c.source) reported at \(String(describing: errors.first?.location))")
    }

    @Test("a tick with nothing to quote is a single error", arguments: [
        "'", "' ", "(')", "(' )", "''", "'')", "(a ')"
    ])
    func danglingTick(_ source: String) {
        let (_, errors) = Self.parse(source)
        #expect(
            errors.map(\.reason) == [.expectedExpressionAfterTick],
            "\(source) gave \(errors.map(\.reason))")
    }

    @Test("a malformed source yields no forms to evaluate", arguments: [
        "(1 2", "((1)", ")", "'", "(' )", "'')"
    ])
    func noPartialForms(_ source: String) {
        let (forms, errors) = Self.parse(source)
        #expect(!errors.isEmpty, "\(source) was expected to fail")
        #expect(
            forms.isEmpty,
            "\(source) produced \(forms.map { "\($0)" }) alongside its error")
    }

    // MARK: Nesting Depth

    /// The parser keeps its own work stack rather than recursing, so nesting
    /// depth is bounded by the heap.
    ///
    /// The depth here is a compromise. It is far past where a recursive parser
    /// fails on a test thread — a few hundred — but stays under the point where
    /// *releasing* the parsed tree overflows the stack, since that teardown is
    /// the runtime's and still recurses.
    @Test("deep nesting does not consume the host stack")
    func deepNesting() {
        let depth = 800
        let source = String(repeating: "(", count: depth) + String(repeating: ")", count: depth)
        let (forms, errors) = Self.parse(source)

        #expect(errors.isEmpty, "deep nesting gave \(errors.map(\.reason))")
        #expect(forms.count == 1)

        var innermost = forms.first
        var measured = 0
        while let list = innermost?.asList(), let first = list.first {
            innermost = first
            measured += 1
        }

        #expect(measured == depth - 1, "unwound \(measured) levels (expected \(depth - 1))")
    }

    // MARK: Whitespace And Layout

    @Test("layout does not change the forms produced", arguments: [
        ("(a b)", "( a b )"),
        ("(a b)", "(a\nb)"),
        ("'(a)", "'( a )"),
        ("(a (b))", "(a\n  (b))")
    ] as [(lhs: String, rhs: String)])
    func layoutIsIgnored(_ c: (lhs: String, rhs: String)) {
        #expect(Self.rendered(c.lhs) == Self.rendered(c.rhs))
    }

}
