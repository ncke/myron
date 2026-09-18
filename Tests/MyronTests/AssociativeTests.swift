import Testing
@testable import Myron

// MARK: - Associative

@Suite("Standard Associative")

struct StandardAssociativeTests {

    @Test("argument must be a list or hashmap", arguments: [
        ("(get 1 7)", .unexpectedType(.integer, [.list, .hashmap])),
        ("(keys \"a\")", .unexpectedType(.string, [.list, .hashmap])),
        ("(put 1 2 7)", .unexpectedType(.integer, [.list, .hashmap]))
    ] as [FailureCase])
    func notAList(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("an associative name reports the arity it wants", arguments: [
        ("(get 1)", .unexpectedArity(1, .exactly(2))),
        ("(get 1 2 3)", .unexpectedArity(3, .exactly(2))),
        ("(get-or 1 2)", .unexpectedArity(2, .exactly(3))),
        ("(put 1 2)", .unexpectedArity(2, .exactly(3))),
        ("(remove 1)", .unexpectedArity(1, .exactly(2))),
        ("(has-key? 1)", .unexpectedArity(1, .exactly(2))),
        ("(keys)", .unexpectedArity(0, .exactly(1))),
        ("(values)", .unexpectedArity(0, .exactly(1)))
    ] as [FailureCase])
    func associativeArity(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a shared name works over either associative type", arguments: [
        ("(get \"a\" '((\"a\" 1)))", "1"),
        ("(get \"a\" (make-hashmap '((\"a\" 1))))", "1"),
        ("(get-or 0 \"z\" '((\"a\" 1)))", "0"),
        ("(get-or 0 \"z\" (make-hashmap '((\"a\" 1))))", "0"),
        ("(has-key? \"a\" '((\"a\" 1)))", "true"),
        ("(has-key? \"a\" (make-hashmap '((\"a\" 1))))", "true"),
        ("(keys '((\"a\" 1)))", "(\"a\")"),
        ("(keys (make-hashmap '((\"a\" 1))))", "(\"a\")"),
        ("(values '((\"a\" 1)))", "(1)"),
        ("(values (make-hashmap '((\"a\" 1))))", "(1)"),
        ("(remove \"a\" '((\"a\" 1)))", "()"),
        ("(put \"b\" 2 '((\"a\" 1)))", "((\"a\" 1) (\"b\" 2))")
    ] as [ValueCase])
    func sharedAssociativeName(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

}
