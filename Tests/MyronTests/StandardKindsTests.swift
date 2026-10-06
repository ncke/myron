import Testing
@testable import Myron

// MARK: - Kinds

@Suite("Standard Kinds")

struct StandardKindsTests {

    @Test("kind", arguments: [
        ("(kind 1)", "\"integer\""),
        ("(kind 1.0)", "\"double\""),
        ("(kind true)", "\"boolean\""),
        ("(kind \"a\")", "\"string\""),
        ("(kind 'a)", "\"symbol\""),
        ("(kind '(1 2))", "\"list\""),
        ("(kind '())", "\"list\""),
        ("(kind (set 1))", "\"set\""),
        ("(kind (make-hashmap))", "\"hashmap\""),
        ("(kind nothing)", "\"nothing\""),
        ("(kind (head '()))", "\"nothing\"")
    ] as [ValueCase])
    func kind(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("callables report their kind", arguments: [
        ("(kind +)", "\"primitive\""),
        ("(kind sqrt)", "\"primitive\""),
        ("(kind map)", "\"primitive\""),
        ("(kind all)", "\"primitive\""),
        ("(kind (lambda (x) x))", "\"procedure\""),
        ("(begin (define (f x) x) (kind f))", "\"procedure\"")
    ] as [ValueCase])
    func kindOfCallable(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("kind gives back a string", arguments: [
        ("(string? (kind 1))", "true"),
        ("(eq (kind 1) (kind 2))", "true"),
        ("(eq (kind 1) (kind 1.0))", "false")
    ] as [ValueCase])
    func kindIsAString(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("make-symbol turns a string into a symbol", arguments: [
        ("(make-symbol \"abc\")", "abc"),
        ("(eq (make-symbol \"abc\") 'abc)", "true"),
        ("(kind (make-symbol \"abc\"))", "\"symbol\""),
        ("(make-symbol (append (string 'point) \"-\" (string 'x)))", "point-x")
    ] as [ValueCase])
    func makeSymbol(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a macro can name what it defines with make-symbol")
    func makeSymbolInMacro() {
        let source = "(defmacro (def-getter type field)"
            + " `(define (,(make-symbol (append (string type) \"-\" (string field))) r)"
            + " (head (tail r))))"
            + " (def-getter point x) (point-x '(point 3))"
        expectValue(source, "3")
    }

    @Test("make-symbol errors", arguments: [
        ("(make-symbol)", .unexpectedArity(0, .exactly(1))),
        ("(make-symbol 5)", .unexpectedType(.integer, [.string]))
    ] as [FailureCase])
    func makeSymbolErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // A symbol from make-symbol is one that source could write with a tick.
    @Test("make-symbol rejects a name that would not read back as that symbol", arguments: [
        ("(make-symbol \"\")", ""),
        ("(make-symbol \"two words\")", "two words"),
        ("(make-symbol \"42\")", "42"),
        ("(make-symbol \"true\")", "true"),
        ("(make-symbol \"nothing\")", "nothing"),
        ("(make-symbol \",x\")", ",x"),
        ("(make-symbol \"`x\")", "`x"),
        ("(make-symbol \"'x\")", "'x")
    ])
    func makeSymbolRejectsUnwritableNames(source: String, name: String) {
        expectFailure(source, reason: .invalidName(name))
    }

    @Test("make-symbol accepts any symbol that source could write", arguments: [
        ("(make-symbol \"a.b\")", "a.b"),
        ("(make-symbol \"nothing?\")", "nothing?"),
        ("(make-symbol \"café\")", "café"),
        ("(make-symbol \"if\")", "if"),
        ("(make-symbol \"x.\")", "x."),
        ("(make-symbol \"xs...\")", "xs..."),
        ("(eq (make-symbol \"if\") 'if)", "true"),
        ("(eq (make-symbol \"x.\") 'x.)", "true")
    ] as [ValueCase])
    func makeSymbolAcceptsWritableNames(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // Binding is checked where it happens, as for a quoted symbol.
    @Test("a symbol make-symbol accepts may still be a name that cannot be bound")
    func makeSymbolThenBind() throws {
        let source = "(defmacro (m) `(define ,(make-symbol \"if\") 1)) (m)"
        let error = try #require(MyronSession().eval(source).asFailure?.first)
        #expect(error.reason == .invalidName("if"))
        #expect(error.hints == [.cannotUseReservedName("if")])
        expectValue("(defmacro (m) (list (make-symbol \"if\") true 1 2)) (m)", "1")
    }

    @Test("kind errors", arguments: [
        ("(kind)", .unexpectedArity(0, .exactly(1))),
        ("(kind 1 2)", .unexpectedArity(2, .exactly(1)))
    ] as [FailureCase])
    func kindErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
