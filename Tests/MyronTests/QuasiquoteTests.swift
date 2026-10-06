import Testing
@testable import Myron

// MARK: - Quasiquote Tests

// A backtick makes a template: `,expr` inside it is evaluated and its value put
// in its place, and `,@expr` is evaluated and its elements spliced in. A plain
// quote never evaluates anything, so a comma inside one is data.

@Suite("Quasiquote")

struct QuasiquoteTests {

    private static func firstError(_ source: String) throws -> MyronError {
        try #require(MyronSession().eval(source).asFailure?.first)
    }

    private static func location(of text: String, in source: String) throws -> MyronLocation {
        let range = try #require(source.range(of: text, options: .backwards))
        let start = source.distance(from: source.startIndex, to: range.lowerBound)
        return start..<(start + text.count)
    }

    // MARK: Unquote

    @Test("an unquoted expression is evaluated and its value put in its place", arguments: [
        ("(define x 5) `(a ,x)", "(a 5)"),
        ("`(a ,(+ 1 2) b)", "(a 3 b)"),
        ("`(,(+ 1 1) ,(+ 2 2))", "(2 4)"),
        ("`(a (b ,(+ 1 1)))", "(a (b 2))"),
        ("`((,1))", "((1))"),
        ("`(a ,(list 1 2) b)", "(a (1 2) b)"),
        ("`(a ,\"s\" ,true ,nothing)", "(a \"s\" true <nothing>)")
    ] as [ValueCase])
    func unquote(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a template that is only an unquote gives the value")
    func wholeUnquote() {
        expectValue("(define x 5) `,x", "5")
        expectValue("`,(list 1 2)", "(1 2)")
    }

    @Test("an unquote sees the environment where the template is evaluated", arguments: [
        ("(let ((x 2)) `(a ,x))", "(a 2)"),
        ("(define (f n) `(n is ,n)) (f 3)", "(n is 3)"),
        ("(define (adder n) (lambda (x) `(,n plus ,x))) ((adder 1) 2)", "(1 plus 2)")
    ] as [ValueCase])
    func unquoteEnvironment(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // A value put in by an unquote is not walked again.
    @Test("an unquoted value is not itself unquoted")
    func valueNotRewalked() {
        expectValue("(define x '(unquote y)) `(a ,x)", "(a (unquote y))")
    }

    @Test("an unquoted value may be anything, as data")
    func anyValueAsData() {
        expectValue("(kind (head (tail `(a ,(lambda (x) x)))))", "\"procedure\"")
    }

    @Test("a template without commas is plain data", arguments: [
        ("`(1 (2 (3)) () nothing)", "(1 (2 (3)) () <nothing>)"),
        ("`a", "a"),
        ("`5", "5"),
        ("`()", "()")
    ] as [ValueCase])
    func plainTemplate(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Quote

    @Test("a quote never evaluates, so a comma inside one is data", arguments: [
        ("(define b 1) '(a ,b)", "(a (unquote b))"),
        ("'(a ,@b)", "(a (unquote-splicing b))"),
        ("',b", "(unquote b)"),
        ("'`(a ,b)", "(quasiquote (a (unquote b)))"),
        ("(define b 1) (eq '(a ,b) (list 'a (list 'unquote 'b)))", "true")
    ] as [ValueCase])
    func quoteIsInert(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Splicing

    @Test("a spliced list's elements are put in its place", arguments: [
        ("`(a ,@(list 1 2) b)", "(a 1 2 b)"),
        ("`(,@(list 1 2) b)", "(1 2 b)"),
        ("`(a ,@(list 1 2))", "(a 1 2)"),
        ("`(a ,@'() b)", "(a b)"),
        ("`(,@(list 1) ,@(list 2 3))", "(1 2 3)"),
        ("`(a (b ,@(list 1 2)) c)", "(a (b 1 2) c)"),
        ("`(a ,@(list '(1) '(2)) b)", "(a (1) (2) b)")
    ] as [ValueCase])
    func splicing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Nesting

    // A quote inside a template is data like any other, so a comma inside it
    // still belongs to the template. This is how a value is put into an
    // expansion as quoted data.
    @Test("a quote inside a template is filled in with the template", arguments: [
        ("(define x 5) `(a ',x)", "(a (quote 5))"),
        ("(define x 5) `(a '(b ,x))", "(a (quote (b 5)))"),
        ("`(a '(b ,@(list 1 2)))", "(a (quote (b 1 2)))")
    ] as [ValueCase])
    func quoteInsideTemplate(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // A backtick inside a template opens a level of its own, and a comma
    // belongs to the innermost backtick around it. Only a comma that belongs
    // to the outermost one is evaluated.
    @Test("a template inside a template keeps its own commas", arguments: [
        ("(define x 5) `(a `(b ,x))", "(a (quasiquote (b (unquote x))))"),
        ("(define x 5) `(a `(b ,,x))", "(a (quasiquote (b (unquote 5))))"),
        ("(define x 5) `(a `(b ,(c ,x)))", "(a (quasiquote (b (unquote (c 5)))))"),
        ("``(a ,b)", "(quasiquote (a (unquote b)))"),
        ("(define x 5) ``(a ,,x)", "(quasiquote (a (unquote 5)))")
    ] as [ValueCase])
    func nestedTemplates(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("unquotes are evaluated from left to right")
    func evaluationOrder() {
        expectValue(
            "(try (lambda (m) m) (`(,(raise \"first\") ,(raise \"second\"))))",
            "\"first\"")
    }

    // MARK: Macros

    @Test("a macro can write its expansion as a template", arguments: [
        ("(defmacro (unless test then else) `(if ,test ,else ,then))"
            + " (unless (== 1 0) 1 (/ 1 0))", "1"),
        ("(defmacro (when test body...) `(if ,test (begin ,@body) nothing))"
            + " (when true 1 2 3)", "3"),
        ("(defmacro (when test body...) `(if ,test (begin ,@body) nothing))"
            + " (when false 1)", "<nothing>"),
        ("(defmacro (q x) `(list ',x)) (q (a b))", "((a b))")
    ] as [ValueCase])
    func macroTemplates(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // A macro's arguments arrive as written, and a quote in its expansion is
    // inert, so a comma in an argument stays data all the way through.
    @Test("a comma in a macro's argument is never evaluated", arguments: [
        ("(defmacro (m x) (list 'quote x)) (m (a ,b))", "(a (unquote b))"),
        ("(defmacro (code x) `(list ',x)) (code (a ,y))", "((a (unquote y)))"),
        ("(defmacro (m x) (kind x)) (m ,y)", "\"list\"")
    ] as [ValueCase])
    func macroArgumentsInert(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // The outer template is filled in when `def-twice` expands; the inner one
    // each time the macro it defines expands, with that macro's own `e`.
    @Test("a macro can write a macro whose expansion is a template")
    func macroWritingMacro() {
        let source = "(defmacro (def-twice name) `(defmacro (,name e) `(list ,e ,e)))"
            + " (def-twice twice) (twice (+ 1 2))"
        expectValue(source, "(3 3)")
    }

    @Test("an unquoted value that is not code fails in an expansion")
    func notCodeInExpansion() throws {
        let error = try Self.firstError("(defmacro (m) `(list ,(lambda () 1))) (m)")
        #expect(error.reason == .valueIsNotCode(.procedure))
    }

    // MARK: Errors

    @Test("a comma outside a template is an error", arguments: [
        ("(define b 1) ,b", ",b"),
        ("(list ,@(list 1))", ",@(list 1)"),
        ("(unquote 1)", "(unquote 1)"),
        ("(unquote-splicing 1)", "(unquote-splicing 1)")
    ])
    func unquoteOutsideTemplate(source: String, located: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .unexpectedUnquoting)
        #expect(error.hints == [.unquoteOnlyInsideTemplate])
        #expect(error.location == (try Self.location(of: located, in: source)))
    }

    @Test("a splice with no list around it is an error")
    func spliceWithoutList() throws {
        let source = "`,@(list 1 2)"
        let error = try Self.firstError(source)
        #expect(error.reason == .unexpectedUnquoting)
        #expect(error.hints == [.unquoteSplicingOnlyInsideList])
        #expect(error.location == (try Self.location(of: ",@(list 1 2)", in: source)))
    }

    // Sets are not spliced: they have no order to splice in.
    @Test("only a list can be spliced", arguments: [
        ("`(a ,@5 b)", ",@5", MyronValue.Kind.integer),
        ("`(a ,@(set 1 2) b)", ",@(set 1 2)", .set),
        ("`(a ,@\"s\" b)", ",@\"s\"", .string)
    ])
    func spliceNotList(source: String, located: String, kind: MyronValue.Kind) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .unexpectedType(kind, [.list]))
        #expect(error.location == (try Self.location(of: located, in: source)))
    }

    @Test("an unquote takes exactly one expression", arguments: [
        ("`(a (unquote) b)", "(unquote)", 0),
        ("`(a (unquote 1 2) b)", "(unquote 1 2)", 2),
        ("`(a (unquote-splicing) b)", "(unquote-splicing)", 0),
        ("`(unquote 1 2)", "(unquote 1 2)", 2)
    ])
    func unquoteArity(source: String, located: String, got: Int) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .unexpectedArity(got, .exactly(1)))
        #expect(error.location == (try Self.location(of: located, in: source)))
    }

    @Test("an error inside an unquote is reported as itself")
    func errorInsideUnquote() {
        expectFailure("`(a ,(/ 1 0))", reason: .divisionByZero)
        expectValue("(try (lambda (m) m) (`(a ,(raise \"no\"))))", "\"no\"")
    }

    @Test("quasiquote, unquote and unquote-splicing cannot be bound", arguments: [
        ("(define quasiquote 1)", "quasiquote"),
        ("(define unquote 1)", "unquote"),
        ("(let ((unquote-splicing 1)) 1)", "unquote-splicing"),
        ("(lambda (quasiquote) 1)", "quasiquote")
    ])
    func reservedNames(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [.cannotUseReservedName(name)])
    }

    // MARK: Depth

    private static func session(limit: Int?) -> MyronSession {
        MyronSession(configuration: MyronSessionConfiguration(
            errorStyle: .terse,
            maximumStackDepth: limit))
    }

    @Test("a template in a loop does not grow the stack")
    func loop() {
        let source = "(define (loop n) (if (== n 0) 'done"
            + " (begin `(a (b ,n) ,@(list n)) (loop (- n 1))))) (loop 100000)"
        #expect(Self.session(limit: 10).eval(source).asSuccess?.description == "done")
    }

    // Each level of a template is a frame while an unquote inside it is
    // evaluated, so deep templates count towards the limit. The nested value is
    // also built and released, so this runs on a stack of known size and warns
    // rather than fails.
    @Test("a deep template is bounded by the stack limit, not the host stack")
    func deepTemplate() {
        let depth = 500
        let template = String(repeating: "(", count: depth) + ",x"
            + String(repeating: ")", count: depth)
        let source = "(define x 7) (head (head `" + template + "))"

        let (within, beyond) = onKnownStack { () -> (Bool, MyronError.Reason?) in
            let within = Self.session(limit: 2000).eval(source).isSuccess
            let beyond = Self.session(limit: 100).eval(source).asFailure?.first?.reason
            return (within, beyond)
        }

        var isDepthError = false
        if case .exceededMaximumStackDepth = beyond { isDepthError = true }
        warnUnless(within, "a \(depth)-deep template failed within a limit of 2000")
        warnUnless(
            isDepthError,
            "a \(depth)-deep template gave \(String(describing: beyond)) under a limit of 100")
    }

    // A plain quote is converted in one pass, without frames, so however deep
    // it is it never meets the limit.
    @Test("a deep quote is not bounded by the stack limit")
    func deepQuote() {
        let depth = 500
        let source = "(head (head '" + String(repeating: "(", count: depth) + "x"
            + String(repeating: ")", count: depth) + "))"

        let succeeded = onKnownStack { Self.session(limit: 10).eval(source).isSuccess }
        warnUnless(succeeded, "a \(depth)-deep quote failed under a limit of 10")
    }

}
