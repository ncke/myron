import Testing
@testable import Myron

// MARK: - Macro Tests

@Suite("Macros")

struct MacroTests {

    private static let unless = "(defmacro (unless test then else) (list 'if test else then))"

    private static let when = "(defmacro (when test body...) (list 'if test (cons 'begin body) 'nothing))"

    private static func firstError(_ source: String) throws -> MyronError {
        try #require(MyronSession().eval(source).asFailure?.first)
    }

    // MARK: Definition

    @Test("defmacro evaluates to a define marker and binds a macro")
    func definition() {
        expectValue("(defmacro (m) 1)", "<define: m>")
        expectValue("(defmacro (m) 1) m", "<macro: m>")
        expectValue("(defmacro (m) 1) (kind m)", "\"macro\"")
    }

    @Test("a macro compares by identity")
    func identity() {
        expectValue("(defmacro (m) 1) (eq m m)", "true")
        expectValue("(defmacro (m) 1) (define n m) (defmacro (m) 1) (eq m n)", "false")
    }

    // MARK: Expansion

    @Test("a macro's arguments are not evaluated before it runs")
    func argumentsUnevaluated() {
        expectValue(Self.unless + " (unless (== 1 0) 1 (/ 1 0))", "1")
        expectValue(Self.unless + " (unless (== 1 1) (/ 1 0) 2)", "2")
    }

    @Test("a macro receives its arguments as data", arguments: [
        ("(defmacro (q x) (list 'quote x)) (q (a (b c)))", "(a (b c))"),
        ("(defmacro (count xs...) (length xs)) (count (f 1) b 3)", "3"),
        ("(defmacro (second-of x) (list 'quote (head (tail x)))) (second-of (a b c))", "b")
    ] as [ValueCase])
    func argumentsAsData(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a variadic parameter splices the remaining arguments", arguments: [
        (Self.when + " (when true 1 2 3)", "3"),
        (Self.when + " (when false 1 2 3)", "<nothing>"),
        (Self.when + " (when true)", "<nothing>")
    ] as [ValueCase])
    func variadicSplicing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("nothing in an expansion is the literal, not a name to look up", arguments: [
        ("(defmacro (m) 'nothing) (m)", "<nothing>"),
        ("(defmacro (m) (list 'list nothing 'nothing)) (m)", "(<nothing> <nothing>)")
    ] as [ValueCase])
    func nothingInExpansion(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("an expansion may use any special form", arguments: [
        ("(defmacro (with x v body) (list 'let (list (list x v)) body)) (with a 2 (* a a))", "4"),
        ("(defmacro (both a b) (list 'and a b)) (both true false)", "false"),
        ("(defmacro (always x) (list 'lambda '() x)) ((always 7))", "7")
    ] as [ValueCase])
    func specialFormsInExpansion(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("an expansion that defines binds where the macro is called")
    func definingExpansion() {
        expectValue("(defmacro (def name v) (list 'define name v)) (def x 42) x", "42")
        expectFailure(
            "(defmacro (def name v) (list 'define name v)) ((lambda () (def y 1) y)) y",
            reason: .unrecognisedSymbol)
    }

    @Test("a macro may expand into another macro")
    func macroIntoMacro() {
        expectValue(
            Self.unless + " (defmacro (if-not test then else) (list 'unless test then else))"
                + " (if-not false 1 2)",
            "1")
    }

    @Test("a macro's code runs in the environment where it was defined")
    func transformerEnvironment() {
        expectValue(
            "(define (plus-one x) (list '+ x 1)) (defmacro (inc x) (plus-one x)) (inc 4)",
            "5")
        expectValue(
            "(define (wrap) (define tag 'list) (defmacro (m x) (list tag x x)) (m 3)) (wrap)",
            "(3 3)")
    }

    // Expansions are not hygienic: a free name in the expansion means whatever
    // it means where the macro is called.
    @Test("an expansion is evaluated in the environment of the call")
    func expansionEnvironment() {
        expectValue("(defmacro (m) 'y) (define y 10) (let ((y 20)) (m))", "20")
    }

    @Test("a macro is looked up when the call is evaluated, not when it is written")
    func callTimeLookup() {
        expectValue("(define (f n) (twice n)) (defmacro (twice x) (list '+ x x)) (f 5)", "10")
    }

    @Test("a macro can be exported from a module", arguments: [
        ("(module mm (w) (defmacro (w x) (list 'list x x))) (mm.w 3)", "(3 3)"),
        ("(module mm (w) (defmacro (w x) (list 'list x x))) (import mm) (w 3)", "(3 3)")
    ] as [ValueCase])
    func modules(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a raise from a macro's code can be caught")
    func raiseInTransformer() {
        expectValue(
            "(defmacro (m) (raise \"nope\")) (try (lambda (e) (list 'caught e)) ((m)))",
            "(caught \"nope\")")
    }

    // MARK: Depth

    private static func session(limit: Int) -> MyronSession {
        MyronSession(configuration: MyronSessionConfiguration(
            errorStyle: .terse,
            maximumStackDepth: limit))
    }

    @Test("a macro call in tail position stays in tail position")
    func tailPosition() {
        let source = Self.unless
            + " (define (loop n) (unless (== n 0) (loop (- n 1)) 0)) (loop 100000)"
        #expect(Self.session(limit: 10).eval(source).asSuccess?.description == "0")
    }

    @Test("a long chain of expansions does not grow the stack")
    func expansionChain() {
        let source = "(defmacro (deep n) (if (== n 0) 0 (list 'deep (- n 1)))) (deep 100000)"
        #expect(Self.session(limit: 10).eval(source).asSuccess?.description == "0")
    }

    // MARK: Errors at the Call

    @Test("a macro call checks its arity", arguments: [
        ("(defmacro (m a b) a) (m 1)", .unexpectedArity(1, .exactly(2))),
        ("(defmacro (m a b) a) (m 1 2 3)", .unexpectedArity(3, .exactly(2))),
        ("(defmacro (m a b...) a) (m)", .unexpectedArity(0, .atLeast(1)))
    ] as [FailureCase])
    func callArity(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("an expansion holding a value that is not code is rejected", arguments: [
        ("(defmacro (m) (list (lambda () 1))) (m)", MyronValue.Kind.procedure),
        ("(defmacro (m) (make-hashmap)) (m)", .hashmap),
        ("(defmacro (m) (list 'list (set 1))) (m)", .set)
    ])
    func expansionNotCode(source: String, kind: MyronValue.Kind) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .valueIsNotCode(kind))
        #expect(error.hints == [.onlyAtomsAndListsAreCode])
    }

    @Test("an error in an expansion is located at the call")
    func errorLocatedAtCall() throws {
        let source = "(defmacro (bad) (list '/ 1 0)) (bad)"
        let error = try Self.firstError(source)
        let call = try #require(source.range(of: "(bad)", options: .backwards))
        let start = source.distance(from: source.startIndex, to: call.lowerBound)

        #expect(error.reason == .divisionByZero)
        #expect(error.location == start..<(start + 5))
    }

    @Test("a macro is not a function")
    func notAFunction() {
        expectFailure("(defmacro (m a) a) (map m '(1))", reason: .expectedFunction(.macro))
        expectFailure("(defmacro (m a) a) (apply m '(1))", reason: .expectedFunction(.macro))
    }

    // MARK: Errors at the Definition

    @Test("a malformed defmacro is rejected", arguments: [
        ("(defmacro)", .unexpectedArity(0, .atLeast(2))),
        ("(defmacro (m))", .unexpectedArity(1, .atLeast(2))),
        ("(defmacro () 1)", .unexpectedArity(0, .atLeast(1))),
        ("(defmacro m 1)", .unexpectedType(.symbol, [.list])),
        ("(defmacro (1 x) x)", .unexpectedType(.integer, [.symbol])),
        ("(defmacro (m 1) 1)", .unexpectedType(.integer, [.symbol]))
    ] as [FailureCase])
    func malformedDefinition(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a macro's name must be one that could be bound", arguments: [
        ("(defmacro (if x) x)", "if", MyronError.Hint.cannotUseReservedName("if")),
        ("(defmacro (defmacro x) x)", "defmacro", .cannotUseReservedName("defmacro")),
        ("(defmacro (m. x) x)", "m.", .nameCannotEndInDot("m."))
    ])
    func invalidName(source: String, name: String, hint: MyronError.Hint) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [hint])
    }

    @Test("a macro's parameters follow the rules for a procedure's", arguments: [
        ("(defmacro (m x x) x)", MyronError.Reason.duplicateName("x"), MyronError.Hint.parameterNamesMustBeUnique),
        ("(defmacro (m xs xs...) xs)", .duplicateName("xs"), .parameterNamesMustBeUnique),
        ("(defmacro (m ...) 1)", .unexpectedVariadicParameter("..."), .bareVariadicEncountered),
        ("(defmacro (m a... b...) 1)", .unexpectedVariadicParameter("b..."), .tooManyVariadics),
        ("(defmacro (m x.) 1)", .invalidName("x."), .nameCannotEndInDot("x."))
    ])
    func parameterRules(source: String, reason: MyronError.Reason, hint: MyronError.Hint) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == reason)
        #expect(error.hints == [hint])
    }

    // MARK: Duplicate Parameters

    // Duplicate names are checked wherever a parameter list is parsed, so they
    // are now rejected for procedures as well as macros.
    @Test("a procedure's parameter names must be unique", arguments: [
        ("(lambda (x x) x)", "x"),
        ("(lambda (a b a) a)", "a"),
        ("(lambda (xs xs...) xs)", "xs"),
        ("(define (f a a) a)", "a")
    ])
    func duplicateProcedureParameters(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .duplicateName(name))
        #expect(error.hints == [.parameterNamesMustBeUnique])
    }

}
