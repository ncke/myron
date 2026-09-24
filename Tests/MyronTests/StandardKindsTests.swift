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

    @Test("kind errors", arguments: [
        ("(kind)", .unexpectedArity(0, .exactly(1))),
        ("(kind 1 2)", .unexpectedArity(2, .exactly(1)))
    ] as [FailureCase])
    func kindErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
