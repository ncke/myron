import Testing
@testable import Myron

// MARK: - Variadic Tests

@Suite("Variadic Parameters")

struct VariadicTests {

    private static func firstError(_ source: String) throws -> MyronError {
        try #require(MyronSession().eval(source).asFailure?.first)
    }

    // MARK: Binding

    @Test("a trailing variadic parameter collects the remaining arguments", arguments: [
        ("((lambda (xs...) xs) 1 2 3)", "(1 2 3)"),
        ("((lambda (xs...) xs) 1)", "(1)"),
        ("((lambda (xs...) xs))", "()"),
        ("((lambda (a xs...) (list a xs)) 1 2 3)", "(1 (2 3))"),
        ("((lambda (a b xs...) (list a b xs)) 1 2 3 4)", "(1 2 (3 4))"),
        ("((lambda (a b xs...) (list a b xs)) 1 2)", "(1 2 ())")
    ] as [ValueCase])
    func trailingVariadic(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a variadic parameter may come before fixed parameters", arguments: [
        ("((lambda (xs... z) (list xs z)) 1 2 3)", "((1 2) 3)"),
        ("((lambda (xs... z) (list xs z)) 1)", "(() 1)"),
        ("((lambda (a xs... z) (list a xs z)) 1 2 3 4)", "(1 (2 3) 4)"),
        ("((lambda (a xs... z) (list a xs z)) 1 2)", "(1 () 2)"),
        ("((lambda (a xs... y z) (list a xs y z)) 1 2 3 4 5)", "(1 (2 3) 4 5)")
    ] as [ValueCase])
    func leadingAndMiddleVariadic(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the variadic parameter is always bound to a list", arguments: [
        ("((lambda (xs...) (list? xs)))", "true"),
        ("((lambda (xs...) (list? xs)) 1)", "true"),
        ("((lambda (xs...) xs) '(1 2))", "((1 2))"),
        ("((lambda (xs...) (length xs)) '() '())", "2")
    ] as [ValueCase])
    func boundToList(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("define's function form accepts a variadic parameter", arguments: [
        ("(define (f a xs...) (list a xs)) (f 1 2 3)", "(1 (2 3))"),
        ("(define (f xs...) (length xs)) (f)", "0"),
        ("(define (f xs... z) z) (f 1 2 3)", "3")
    ] as [ValueCase])
    func defineForm(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a variadic parameter is bound without its '...'")
    func boundWithoutEllipsis() {
        expectValue("(define (f xs...) xs) (f 1 2)", "(1 2)")
    }

    @Test("a variadic parameter shadows an outer binding")
    func shadowing() {
        expectValue("(define xs 99) ((lambda (xs...) xs) 1 2)", "(1 2)")
    }

    @Test("a variadic lambda closes over its environment")
    func closure() {
        expectValue(
            "(define (adder n) (lambda (xs...) (map (lambda (x) (+ x n)) xs))) ((adder 10) 1 2)",
            "(11 12)")
    }

    // MARK: Higher-Order Functions

    @Test("variadic procedures can be passed to higher-order functions", arguments: [
        ("(apply (lambda (xs...) xs) '(1 2 3))", "(1 2 3)"),
        ("(apply (lambda (a xs...) (list a xs)) 1 '(2 3))", "(1 (2 3))"),
        ("(apply (lambda (xs...) xs) '())", "()"),
        ("(map (lambda (xs...) xs) '(1 2))", "((1) (2))"),
        ("(filter (lambda (xs...) (> (head xs) 1)) '(1 2 3))", "(2 3)"),
        ("(reduce (lambda (xs...) (apply + xs)) 0 '(1 2 3))", "6"),
        ("(foldr (lambda (xs...) (apply + xs)) 0 '(1 2 3))", "6"),
        ("(any (lambda (xs...) (== (length xs) 1)) '(1 2))", "true")
    ] as [ValueCase])
    func higherOrder(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a variadic procedure can recurse by applying itself to the rest")
    func recursion() {
        expectValue(
            """
            (define (sum xs...)
              (if (empty? xs) 0 (+ (head xs) (apply sum (tail xs)))))
            (sum 1 2 3 4)
            """,
            "10")
    }

    // MARK: Arity

    @Test("too few arguments for the fixed parameters is an arity error", arguments: [
        ("((lambda (a xs...) a))", .unexpectedArity(0, .atLeast(1))),
        ("((lambda (a b xs...) a) 1)", .unexpectedArity(1, .atLeast(2))),
        ("((lambda (xs... z) z))", .unexpectedArity(0, .atLeast(1))),
        ("((lambda (a xs... z) a) 1)", .unexpectedArity(1, .atLeast(2))),
        ("(define (f a xs...) a) (f)", .unexpectedArity(0, .atLeast(1))),
        ("(apply (lambda (a b xs...) a) '(1))", .unexpectedArity(1, .atLeast(2)))
    ] as [FailureCase])
    func tooFewArguments(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: Malformed Parameters

    @Test("more than one variadic parameter is rejected", arguments: [
        ("(lambda (a... b...) 1)", "b..."),
        ("(lambda (a... x b...) 1)", "b..."),
        ("(lambda (x a... b... c...) 1)", "b..."),
        ("(define (f a... b...) 1)", "b...")
    ])
    func tooManyVariadics(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .unexpectedVariadicParameter(name))
        #expect(error.hints == [.tooManyVariadics])
    }

    @Test("a bare '...' parameter is rejected", arguments: [
        "(lambda (...) 1)",
        "(lambda (a ...) 1)",
        "(define (f ...) 1)"
    ])
    func bareVariadic(source: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .unexpectedVariadicParameter("..."))
        #expect(error.hints == [.bareVariadicEncountered])
    }

    @Test("a variadic name that still ends in a dot without its '...' is rejected", arguments: [
        ("(lambda (x....) 1)", "x."),
        ("(lambda (a x..... b) 1)", "x.."),
        ("(lambda (....) 1)", "."),
        ("(define (f x....) 1)", "x.")
    ])
    func variadicNameEndsInDot(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [.nameCannotEndInDot(name)])
    }

    @Test("a variadic name may contain a dot that is not at its end")
    func dotInsideVariadicName() {
        expectValue("((lambda (a.b...) a.b) 1 2)", "(1 2)")
    }

    @Test("a malformed parameter list is reported when the procedure is made, not called")
    func reportedAtDefinition() {
        expectFailure("(define (f a... b...) 1) 2", reason: .unexpectedVariadicParameter("b..."))
    }

}
