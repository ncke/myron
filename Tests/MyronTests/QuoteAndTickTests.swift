import Testing
@testable import Myron

// MARK: - Quote and Tick

@Suite("Quote and Tick")

struct QuoteAndTickTests {

    @Test("quote longhand yields data rather than application", arguments: [
        ("(quote (1 2 3))", "(1 2 3)"),
        ("(quote a)", "a"),
        ("(quote ())", "()"),
        ("(quote (+ 1 2))", "(+ 1 2)")
    ] as [ValueCase])
    func quoteLonghand(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("tick abbreviates quote", arguments: [
        ("'(1 2 3)", "(1 2 3)"),
        ("'a", "a"),
        ("'()", "()"),
        ("'(+ 1 2)", "(+ 1 2)")
    ] as [ValueCase])
    func tick(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("tick and quote are equivalent", arguments: [
        ("(eq '(1 2 3) (quote (1 2 3)))", "true"),
        ("(eq 'a (quote a))", "true"),
        ("(eq '() (quote ()))", "true")
    ] as [ValueCase])
    func equivalence(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("nested tick quotes the quotation")
    func nestedTick() {
        expectValue("''a", "(quote a)")
        expectValue("(eq ''a (quote (quote a)))", "true")
    }

    @Test("tick works in argument position", arguments: [
        ("(head '(1 2 3))", "1"),
        ("(tail '(1 2 3))", "(2 3)"),
        ("(eq '(1 2) '(1 2))", "true"),
        ("(reduce + 0 '(1 2 3 4 5))", "15")
    ] as [ValueCase])
    func argumentPosition(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("dangling tick is a single error", arguments: [
        "'",
        "(head ')",
        "(list ' )"
    ])
    func danglingTick(_ source: String) {
        expectFailure(source, reason: .expectedExpressionAfterTick)
    }

    @Test("quote rejects the wrong arity", arguments: [
        ("(quote)", .unexpectedArity(0, .exactly(1))),
        ("(quote 1 2)", .unexpectedArity(2, .exactly(1)))
    ] as [FailureCase])
    func quoteArity(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
