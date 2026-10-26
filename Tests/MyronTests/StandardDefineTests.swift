import Testing
@testable import Myron

// MARK: - Define

@Suite("Standard Define")

struct StandardDefineTests {

    private static let module = "(module m (a b) (define a 1) (define b 2))"

    @Test("defined-name", arguments: [
        ("(defined-name (define x 1))", "x"),
        ("(defined-name (define (f y) y))", "f"),
        ("(defined-name (defmacro (m y) y))", "m"),
        ("(defined-name \(module))", "m"),
        ("\(module) (map defined-name (import m))", "(a b)")
    ] as [ValueCase])
    func definedName(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("defined-name gives back a symbol", arguments: [
        ("(symbol? (defined-name (define x 1)))", "true"),
        ("(eq (defined-name (define x 1)) 'x)", "true"),
        ("(string (defined-name (define x 1)))", "\"x\"")
    ] as [ValueCase])
    func definedNameIsASymbol(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("does-define?", arguments: [
        ("(does-define? 'x (define x 1))", "true"),
        ("(does-define? \"x\" (define x 1))", "true"),
        ("(does-define? 'y (define x 1))", "false"),
        ("(does-define? \"y\" (define x 1))", "false"),
        ("(does-define? 'f (define (f y) y))", "true"),
        ("\(module) (does-define? 'b (head (tail (import m))))", "true"),
        ("\(module) (map (lambda (d) (does-define? 'a d)) (import m))", "(true false)")
    ] as [ValueCase])
    func doesDefine(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("define errors", arguments: [
        ("(defined-name)", .unexpectedArity(0, .exactly(1))),
        ("(defined-name (define x 1) 2)", .unexpectedArity(2, .exactly(1))),
        ("(does-define? 'x)", .unexpectedArity(1, .exactly(2))),
        ("(defined-name 'x)", .unexpectedType(.symbol, [.define])),
        ("(defined-name \"x\")", .unexpectedType(.string, [.define])),
        ("(does-define? 'x 'x)", .unexpectedType(.symbol, [.define])),
        ("(does-define? 1 (define x 1))", .unexpectedType(.integer, [.string, .symbol]))
    ] as [FailureCase])
    func defineErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
