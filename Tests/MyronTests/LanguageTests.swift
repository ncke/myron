import Testing
@testable import Myron

// MARK: - Language Tests

@Suite("Language") struct LanguageTests {

    @Test("define binds a value")
    func defineValue() {
        expectValue("(define x 5) (+ x 1)", "6")
    }

    @Test("define binds a procedure")
    func defineProcedure() {
        expectValue("(define (square n) (* n n)) (square 4)", "16")
    }

    @Test("procedures close over their definition environment")
    func closure() {
        expectValue(
            "(define k 10) (define (addk n) (+ n k)) (addk 5)",
            "15")
    }

    @Test("if selects the true branch")
    func ifTrue() {
        expectValue("(if (gt 2 1) 10 20)", "10")
    }

    @Test("if selects the false branch")
    func ifFalse() {
        expectValue("(if (lt 2 1) 10 20)", "20")
    }

    @Test("begin evaluates in order and yields the last value", arguments: [
        ("(begin 1 2 3)", "3"),
        ("(begin (define x 5) (define y 6) (* x y))", "30"),
        ("(begin (head '()))", "<nothing>"),
        ("(list (begin 1 2) (begin 3 4))", "(2 4)"),
        ("(if true (begin (define a 1) (+ a 1)) 0)", "2"),
        ("(begin (define (h) 1)) (h)", "1")
    ] as [ValueCase])
    func begin(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("begin defines into the current environment, not a new one")
    func beginScope() {
        expectValue("(begin (define x 5) 1) x", "5")
        expectValue("(define x 1) (begin (define x 2)) x", "2")
    }

    @Test("a define body may contain several expressions", arguments: [
        ("(define (area r) (define r2 (* r r)) (* 3 r2)) (area 2)", "12"),
        ("(define (f x) 1 2 x) (f 9)", "9"),
        ("(define (f) (define g 1)) (f)", "<define: g>"),
        ("(define (f x) (define x 2) x) (f 1)", "2")
    ] as [ValueCase])
    func multiExpressionBody(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("internal defines are local to the call")
    func internalDefinesAreLocal() {
        expectFailure(
            "(define (area r) (define r2 (* r r)) (* 3 r2)) (area 2) r2",
            reason: .unrecognisedSymbol)
        expectValue(
            "(define x 1) (define (f) (define x 2) x) (list (f) x)",
            "(2 1)")
    }

    @Test("internal defines support local helpers, recursion, and closure")
    func internalDefinesCompose() {
        expectValue(
            """
            (define (sum xs)
              (define (go acc ys)
                (if (empty? ys) acc (go (+ acc (head ys)) (tail ys))))
              (go 0 xs))
            (sum '(1 2 3))
            """,
            "6")
        expectValue(
            """
            (define (make-adder n)
              (define (add x) (+ x n))
              add)
            ((make-adder 5) 3)
            """,
            "8")
    }

    @Test("language errors", arguments: [
        ("(if true 1)", .unexpectedArity),
        ("(if 1 10 20)", .typeMismatch),
        ("nonexistent", .unrecognisedSymbol),
        ("()", .emptyApplication),
        ("(begin)", .unexpectedArity),
        ("(define (f))", .unexpectedArity),
        ("(define x 1 2)", .unexpectedArity),
        ("(define (f 1) 1)", .typeMismatch),
        ("(define (f x) 1) (f)", .unexpectedArity),
        ("(define (f) 1) (f 1)", .unexpectedArity)
    ] as [FailureCase])
    func languageErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
