import Testing
@testable import Myron

// MARK: - Lambda Tests

@Suite("Lambda")

struct LambdaTests {

    @Test("a lambda applies immediately", arguments: [
        ("((lambda (x) (* x x)) 5)", "25"),
        ("((lambda (x y) (+ x y)) 3 4)", "7"),
        ("((lambda () 42))", "42")
    ] as [ValueCase])
    func immediateApplication(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a lambda is a value that can be bound and called")
    func boundToName() {
        expectValue("(define add5 (lambda (x) (+ x 5))) (add5 10)", "15")
    }

    @Test("define's function form is sugar for a bound lambda")
    func sugarEquivalence() {
        expectValue("(define (sq x) (* x x)) (sq 6)", "36")
    }

    @Test("a lambda inlines into the higher-order primitives", arguments: [
        ("(map (lambda (x) (+ x 1)) '(1 2 3))", "(2 3 4)"),
        ("(filter (lambda (x) (gt x 0)) '(-1 2 -3 4))", "(2 4)"),
        ("(reduce (lambda (a b) (+ a b)) 0 '(1 2 3 4 5))", "15")
    ] as [ValueCase])
    func inlineHigherOrder(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a lambda captures its defining environment")
    func lexicalCapture() {
        expectValue("(define k 100) ((lambda (x) (+ x k)) 1)", "101")
    }

    @Test("a returned lambda closes over its arguments (currying)")
    func closure() {
        expectValue(
            "(define (adder n) (lambda (x) (+ x n))) ((adder 5) 3)",
            "8")
    }

    @Test("a parameter shadows an outer binding")
    func shadowing() {
        expectValue("(define x 1) ((lambda (x) x) 99)", "99")
    }

    @Test("a lambda body may contain several expressions", arguments: [
        ("((lambda (x) (define y 2) (+ x y)) 1)", "3"),
        ("((lambda () 1 2 3))", "3"),
        ("((lambda (x) (define (sq n) (* n n)) (sq x)) 4)", "16")
    ] as [ValueCase])
    func multiExpressionBody(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a lambda's internal defines do not escape")
    func internalDefinesAreLocal() {
        expectFailure("((lambda () (define y 2) y)) y", reason: .unrecognisedSymbol)
    }

    @Test("arity is enforced at definition and application", arguments: [
        ("(lambda)", .unexpectedArity(0, .atLeast(2))),
        ("(lambda (x))", .unexpectedArity(1, .atLeast(2))),
        ("((lambda (x) x) 1 2)", .unexpectedArity(2, .exactly(1))),
        ("((lambda (x y) x) 1)", .unexpectedArity(1, .exactly(2))),
        ("((lambda () 1) 2)", .unexpectedArity(1, .exactly(0))),
        ("(lambda (1) 1)", .unexpectedType(.integer, [.symbol]))
    ] as [FailureCase])
    func arityErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
