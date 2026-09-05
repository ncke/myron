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

    @Test("let binds names for the extent of its body", arguments: [
        ("(let ((x 5) (y 6)) (* x y))", "30"),
        ("(let ((x 5)) x)", "5"),
        ("(let () 1 2 3)", "3"),
        ("(let ((x 1)) (define y 2) (+ x y))", "3"),
        ("(let ((f (lambda (n) (* n n)))) (f 4))", "16"),
        ("(let ((x (head '()))) (nothing? x))", "true"),
        ("(let ((xs '(1 2 3))) (map (lambda (x) (* x x)) xs))", "(1 4 9)")
    ] as [ValueCase])
    func letBindings(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("let bindings are sequential: later bindings see earlier ones", arguments: [
        ("(let ((x 5) (y (* x 2))) y)", "10"),
        ("(let ((x 1) (x (+ x 1)) (x (* x 10))) x)", "20"),
        ("(define x 1) (let ((x (+ x 1))) x)", "2")
    ] as [ValueCase])
    func letSequential(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("let scope does not escape or clobber", arguments: [
        ("(define x 1) (let ((x 2)) x) x", "1"),
        ("(define x 1) (let ((y 2)) (define x 3) x) x", "1"),
        ("(define counter (let ((n 5)) (lambda () n))) (counter)", "5")
    ] as [ValueCase])
    func letScope(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("names bound or defined in a let are unbound afterwards", arguments: [
        "(let ((x 1)) x) x",
        "(let ((x 1)) (define y 2) y) y",
        "(let () (define z 1) z) z"
    ])
    func letNamesDoNotEscape(_ source: String) {
        expectFailure(source, reason: .unrecognisedSymbol)
    }

    @Test("let errors", arguments: [
        ("(let)", .unexpectedArity),
        ("(let ())", .unexpectedArity),
        ("(let ((x 1)))", .unexpectedArity),
        ("(let x 1)", .expectedBindingsForLet),
        ("(let 5 1)", .expectedBindingsForLet),
        ("(let \"x\" 1)", .expectedBindingsForLet),
        ("(let ((x)) x)", .invalidBindingForLet),
        ("(let ((x 1 2)) x)", .invalidBindingForLet),
        ("(let ((1 2)) 1)", .invalidBindingForLet),
        ("(let (x 1) x)", .invalidBindingForLet),
        ("(let (x) x)", .invalidBindingForLet),
        ("(let ((x undefined)) x)", .unrecognisedSymbol),
        ("(let ((x 1)) undefined)", .unrecognisedSymbol),
        ("(let ((x (/ 1 0))) x)", .divisionByZero)
    ] as [FailureCase])
    func letErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
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
