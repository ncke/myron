import Testing
@testable import Myron

// MARK: - Sequence

@Suite("Standard Sequence")

struct StandardSequenceTests {

    private static let sequenceKinds: Set<Value.Kind> = [.list, .string]
    private static let extendedSequenceKinds: Set<Value.Kind> = [.hashmap, .list, .string]

    @Test("a shared name works over either sequence type", arguments: [
        ("(head '(1 2 3))", "1"),
        ("(head \"abc\")", "\"a\""),
        ("(tail '(1 2 3))", "(2 3)"),
        ("(tail \"abc\")", "\"bc\""),
        ("(init '(1 2 3))", "(1 2)"),
        ("(init \"abc\")", "\"ab\""),
        ("(last '(1 2 3))", "3"),
        ("(last \"abc\")", "\"c\""),
        ("(take 2 '(1 2 3))", "(1 2)"),
        ("(take 2 \"abc\")", "\"ab\""),
        ("(drop 2 '(1 2 3))", "(3)"),
        ("(drop 2 \"abc\")", "\"c\""),
        ("(length '(1 2 3))", "3"),
        ("(length \"abc\")", "3"),
        ("(empty? '())", "true"),
        ("(empty? \"\")", "true"),
        ("(append '(1) '(2))", "(1 2)"),
        ("(append \"a\" \"b\")", "\"ab\""),
        ("(reverse '(1 2 3))", "(3 2 1)"),
        ("(reverse \"abc\")", "\"cba\""),
        ("(nth 1 '(1 2 3))", "2"),
        ("(nth 1 \"abc\")", "\"b\""),
        ("(contains 2 '(1 2 3))", "true"),
        ("(contains \"b\" \"abc\")", "true")
    ] as [ValueCase])
    func sharedNames(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("dispatch inspects the sequence argument, not the first argument")
    func dispatchOnSequencePosition() {
        expectValue("(take 1 \"abc\")", "\"a\"")
        expectValue("(drop 1 \"abc\")", "\"bc\"")
        expectValue("(nth 0 \"abc\")", "\"a\"")
        expectValue("(contains \"a\" \"abc\")", "true")
        expectValue("(contains \"a\" '(\"a\"))", "true")
    }

    @Test("a non-sequence reports the kind found and the kinds expected", arguments: [
        ("(head 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(tail 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(init 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(last 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(take 1 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(drop 1 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(length 5)", .unexpectedType(.integer, extendedSequenceKinds)),
        ("(empty? 5)", .unexpectedType(.integer, extendedSequenceKinds)),
        ("(append 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(reverse 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(nth 0 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(contains 1 5)", .unexpectedType(.integer, sequenceKinds)),
        ("(length 1.5)", .unexpectedType(.double, extendedSequenceKinds)),
        ("(length true)", .unexpectedType(.boolean, extendedSequenceKinds)),
        ("(length 'sym)", .unexpectedType(.symbol, extendedSequenceKinds)),
        ("(length (head '()))", .unexpectedType(.nothing, extendedSequenceKinds)),
        ("(length sqrt)", .unexpectedType(.primitive, extendedSequenceKinds)),
        ("(length (lambda (x) x))", .unexpectedType(.procedure, extendedSequenceKinds)),
        ("(length (define x 1))", .unexpectedType(.define, extendedSequenceKinds))
    ] as [FailureCase])
    func unexpectedType(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a missing sequence argument is an arity error", arguments: [
        "(head)", "(tail)", "(init)", "(last)", "(length)", "(empty?)",
        "(append)", "(reverse)", "(take)", "(take 1)", "(drop)", "(drop 1)",
        "(nth)", "(nth 0)", "(contains)", "(contains 1)"
    ])
    func missingSequence(_ source: String) {
        expectArityFailure(source)
    }

    @Test("surplus arguments are still an arity error", arguments: [
        "(head '(1) '(2))", "(head \"a\" \"b\")", "(length '(1) 2)",
        "(length \"a\" \"b\")", "(reverse \"a\" \"b\")", "(take 1 \"ab\" 3)",
        "(nth 0 \"ab\" 3)"
    ])
    func surplusArguments(_ source: String) {
        expectArityFailure(source)
    }

    @Test("append does not mix sequence types")
    func appendDoesNotMix() {
        expectFailure("(append \"a\" '(1))", reason: .unexpectedType(.list, [.string]))
        expectFailure("(append '(1) \"a\")", reason: .unexpectedType(.string, [.list]))
    }

    @Test("the type error message lists expectations in a stable order")
    func unexpectedTypeMessage() {
        let session = MyronSession()
        for _ in 0..<5 {
            guard case .failure(let errors) = session.eval("(length 5)") else {
                Issue.record("(length 5) did not fail")
                return
            }
            #expect(errors.first?.message?.hasPrefix(
                "ERROR: Unexpected type, got integer, expected hashmap, list, string") == true)
        }
    }

}
