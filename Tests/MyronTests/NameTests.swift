import Testing
@testable import Myron

// MARK: - Name Tests

@Suite("Names")

// A trailing dot is reserved for the `...` of a variadic parameter, so no name
// may end in one, wherever it is bound.

struct NameTests {

    private static func firstError(_ source: String) throws -> MyronError {
        try #require(MyronSession().eval(source).asFailure?.first)
    }

    @Test("a name ending in a dot cannot be bound", arguments: [
        ("(define x. 1)", "x."),
        ("(define . 1)", "."),
        ("(define a.b. 1)", "a.b."),
        ("(define (f. a) a)", "f."),
        ("(define (f a.) a.)", "a."),
        ("(lambda (a.) a.)", "a."),
        ("(lambda (a b..) b..)", "b.."),
        ("(let ((a. 1)) a.)", "a."),
        ("(let ((a 1) (b. 2)) b.)", "b."),
        ("(module m. ())", "m."),
        ("(module m (x.) (define x 1))", "x."),
        ("(make-record-type 'p. '(x))", "p."),
        ("(make-record-type 'p '(x.))", "x.")
    ])
    func trailingDotRejected(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [.nameCannotEndInDot(name)])
    }

    @Test("the trailing dot is rejected before the binding is made")
    func nothingIsBound() {
        let session = MyronSession()
        _ = session.eval("(define x. 1)")
        #expect(session.query("x.") == nil)
    }

    @Test("a host cannot define a primitive whose name ends in a dot", arguments: [
        "x.", ".", "a.b."
    ])
    func hostNameRejected(_ name: String) {
        let session = MyronSession()
        let error = #expect(throws: MyronError.self) {
            try session.define(name) { _ in 1 }
        }

        #expect(error?.reason == .invalidName(name))
        #expect(error?.hints == [.nameCannotEndInDot(name)])
        #expect(session.query(name) == nil)
    }

    @Test("a dot elsewhere in a name is still allowed", arguments: [
        ("(define a.b 1) a.b", "1"),
        ("(define (f.g x) x) (f.g 2)", "2"),
        ("((lambda (a.b) a.b) 3)", "3"),
        ("(let ((a.b 4)) a.b)", "4"),
        ("((lambda (xs...) xs) 5 6)", "(5 6)")
    ] as [ValueCase])
    func innerDotAllowed(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the hint reaches the rendered message")
    func hintInMessage() throws {
        let error = try Self.firstError("(define x. 1)")
        let hint = MyronError.Hint.nameCannotEndInDot("x.")

        #expect(error.message?.contains("HINT: \(hint)") == true)
    }

    // MARK: Reserved Names

    // `nothing` is a literal, like `true` and `false`, so it is not a symbol and
    // cannot be bound anywhere a name is expected.
    @Test("nothing cannot be bound", arguments: [
        ("(define nothing 5)", .unexpectedType(.nothing, [.list, .symbol])),
        ("(define (nothing) 5)", .unexpectedType(.nothing, [.symbol])),
        ("(define (f nothing) 5)", .unexpectedType(.nothing, [.symbol])),
        ("(lambda (nothing) 1)", .unexpectedType(.nothing, [.symbol])),
        ("(let ((nothing 5)) 1)", .unexpectedType(.nothing, [.symbol])),
        ("(defmacro (nothing) 1)", .unexpectedType(.nothing, [.symbol])),
        ("(module nothing ())", .unexpectedType(.nothing, [.symbol])),
        ("(make-record-type 'nothing '(x))", .unexpectedType(.nothing, [.symbol]))
    ] as [FailureCase])
    func nothingCannotBeBound(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a host cannot define nothing")
    func hostCannotDefineNothing() {
        let session = MyronSession()
        let error = #expect(throws: MyronError.self) {
            try session.define("nothing") { _ in 1 }
        }

        #expect(error?.reason == .invalidName("nothing"))
        #expect(session.eval("nothing").asSuccess == .nothing)
    }

    @Test("a special form's name cannot be bound in source", arguments: [
        ("(define if 3)", "if"),
        ("(define (try) 3)", "try"),
        ("(let ((quote 1)) 1)", "quote"),
        ("(let ((x 1) (lambda 2)) x)", "lambda"),
        ("(defmacro (module x) x)", "module"),
        ("(lambda (if) 1)", "if"),
        ("(define (f a cond) a)", "cond"),
        ("(defmacro (m quote) 1)", "quote"),
        ("(lambda (a define...) a)", "define")
    ])
    func specialFormNameCannotBeBound(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [.cannotUseReservedName(name)])
    }

    @Test("a name that only contains a reserved word can be bound", arguments: [
        ("(define nothings 1) nothings", "1"),
        ("(define if-not 2) if-not", "2"),
        ("(let ((try-again 3)) try-again)", "3")
    ] as [ValueCase])
    func reservedWordInsideName(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Agreement With the Lexer

    // Binding checks names without running the lexer, which is too slow for every
    // call. The lexer is the reference, so the cheaper check must agree with it.
    private static func lexesAsSymbol(_ name: String) -> Bool {
        let (tokens, errors) = Lexer(input: name, sourceHandle: nil).tokenize()
        guard
            errors.isEmpty,
            tokens.count == 1,
            case .symbol(let symbol) = tokens[0].kind
        else {
            return false
        }

        return symbol == name
    }

    @Test("a name is a symbol name exactly when the lexer reads it as one", arguments: [
        // Ordinary names.
        "x", "map", "point-x", "x?", "set!", "a.b", "geo.area", "x.", "->x", "x->y",
        "<=", "==", "*", "/", "%", "^", "_", "λ", "naïve", "x1",
        // Punctuation that starts a token, inside a name and at its start.
        "a,b", ",x", ",", ",@x", "a,@b", "a@b", "@x", "@",
        "a`b", "`x", "`", "a'b", "'x", "'",
        // Signs and numbers.
        "+", "-", "+x", "-x", "--", "-1", "+1", "-1a", "-.5", "1", "1a", "1.5", ".5",
        "x1.5",
        // Token breakers.
        "", " ", "two words", " x", "x ", "x\n", "\tx", "(", ")", "a(b", "a)b",
        ";", ";x", "x;y", "x;",
        // Quotes, which the lexer skips over inside a token.
        "\"", "\"s\"", "\"s", "s\"", "a\"b\"", "a\"b c\"", "\"a\"b",
        // Literals.
        "true", "false", "nothing", "nothings", "true?", "falsehood"
    ])
    func agreesWithLexer(_ name: String) {
        // Quotes are stricter than the lexer: it reads `a"b"` as one symbol,
        // since it skips over quoted text inside a token, but no name may hold
        // a quote.
        let expected = Self.lexesAsSymbol(name) && !name.contains("\"")
        #expect(MyronValue.isValidAsSymbolName(name) == expected)
    }

    @Test("a quote inside a name is the one place the check is stricter")
    func quotesAreStricter() {
        #expect(Self.lexesAsSymbol("a\"b\""))
        #expect(!MyronValue.isValidAsSymbolName("a\"b\""))
    }

    @Test("punctuation inside a name can be bound in source", arguments: [
        ("(define a,b 1) a,b", "1"),
        ("(define a@b 2) a@b", "2"),
        ("(define @x 3) @x", "3"),
        ("(define a'b 4) a'b", "4"),
        ("(define a`b 5) a`b", "5"),
        ("(let ((a,b 6)) a,b)", "6"),
        ("((lambda (a@b) a@b) 7)", "7"),
        ("(define (f a'b) a'b) (f 8)", "8")
    ] as [ValueCase])
    func punctuatedNameBinds(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("make-symbol accepts a name source could write", arguments: [
        ("(make-symbol \"a,b\")", "a,b"),
        ("(make-symbol \"@x\")", "@x"),
        ("(make-symbol \"+\")", "+")
    ] as [ValueCase])
    func makeSymbolPunctuated(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Order of Checking

    @Test("define rejects a name before evaluating its value", arguments: [
        ("(define x. (raise \"evaluated\"))", "x."),
        ("(define if (raise \"evaluated\"))", "if")
    ])
    func defineChecksNameFirst(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .invalidName(name))
    }

}
