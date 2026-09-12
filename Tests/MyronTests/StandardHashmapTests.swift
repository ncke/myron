import Testing
@testable import Myron

// MARK: - Hashmaps

@Suite("Standard Hashmap")

struct StandardHashmapTests {

    private static let ab = "(make-hashmap '((\"a\" 1) (\"b\" 2)))"

    // MARK: Construction

    @Test("make-hashmap", arguments: [
        ("(empty? (make-hashmap))", "true"),
        ("(length (make-hashmap))", "0"),
        ("(length (make-hashmap '()))", "0"),
        ("(empty? (make-hashmap '()))", "true"),
        ("(length \(ab))", "2"),
        ("(empty? \(ab))", "false")
    ] as [ValueCase])
    func makeHashmap(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("an alist round trips through a hashmap")
    func roundTrip() {
        expectValue("(eq (make-hashmap (keys-values \(Self.ab))) \(Self.ab))", "true")
    }

    // MARK: Reading

    @Test("get", arguments: [
        ("(get \"a\" \(ab))", "1"),
        ("(get \"b\" \(ab))", "2"),
        ("(get \"z\" \(ab))", "<nothing>"),
        ("(get \"a\" (make-hashmap))", "<nothing>"),
        ("(get 1.5 (make-hashmap '((1.5 \"x\"))))", "\"x\""),
        ("(get true (make-hashmap '((true \"t\") (false \"f\"))))", "\"t\""),
        ("(get false (make-hashmap '((true \"t\") (false \"f\"))))", "\"f\"")
    ] as [ValueCase])
    func get(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("keys are distinguished by type", arguments: [
        ("(get 1 (make-hashmap '((1.0 \"double\") (1 \"integer\"))))", "\"integer\""),
        ("(get 1.0 (make-hashmap '((1.0 \"double\") (1 \"integer\"))))", "\"double\""),
        ("(get 1 (make-hashmap '((true \"boolean\"))))", "<nothing>"),
        ("(get \"1\" (make-hashmap '((1 \"integer\"))))", "<nothing>"),
        ("(length (make-hashmap '((1 \"integer\") (1.0 \"double\"))))", "2")
    ] as [ValueCase])
    func keyTypes(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("get-or", arguments: [
        ("(get-or 0 \"a\" \(ab))", "1"),
        ("(get-or 0 \"z\" \(ab))", "0"),
        ("(get-or 0 \"z\" (make-hashmap))", "0")
    ] as [ValueCase])
    func getOr(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("has-key?", arguments: [
        ("(has-key? \"a\" \(ab))", "true"),
        ("(has-key? \"z\" \(ab))", "false"),
        ("(has-key? \"a\" (make-hashmap))", "false")
    ] as [ValueCase])
    func hasKey(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Writing

    @Test("put", arguments: [
        ("(eq (put \"c\" 3 \(ab)) (make-hashmap '((\"a\" 1) (\"b\" 2) (\"c\" 3))))", "true"),
        ("(eq (put \"a\" 9 \(ab)) (make-hashmap '((\"a\" 9) (\"b\" 2))))", "true"),
        ("(eq (put \"a\" 1 (make-hashmap)) (make-hashmap '((\"a\" 1))))", "true"),
        ("(length (put \"a\" 9 \(ab)))", "2"),
        ("(length (put \"c\" 3 \(ab)))", "3"),
        ("(get \"a\" (put \"a\" 9 \(ab)))", "9")
    ] as [ValueCase])
    func put(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("put leaves the original untouched")
    func putIsPure() {
        expectValue(
            "(define hm \(Self.ab)) (put \"c\" 3 hm) (length hm)",
            "2")
    }

    @Test("putting nothing removes the key", arguments: [
        ("(eq (put \"a\" nothing \(ab)) (make-hashmap '((\"b\" 2))))", "true"),
        ("(has-key? \"a\" (put \"a\" nothing \(ab)))", "false"),
        ("(length (put \"a\" nothing \(ab)))", "1"),
        ("(eq (put \"z\" nothing \(ab)) \(ab))", "true"),
        ("(length (put \"a\" nothing (make-hashmap)))", "0")
    ] as [ValueCase])
    func putNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("remove", arguments: [
        ("(eq (remove \"a\" \(ab)) (make-hashmap '((\"b\" 2))))", "true"),
        ("(eq (remove \"z\" \(ab)) \(ab))", "true"),
        ("(length (remove \"a\" \(ab)))", "1"),
        ("(length (remove \"a\" (make-hashmap)))", "0"),
        ("(has-key? \"a\" (remove \"a\" \(ab)))", "false")
    ] as [ValueCase])
    func remove(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Enumeration

    @Test("a single entry enumerates predictably", arguments: [
        ("(keys (make-hashmap '((\"a\" 1))))", "(\"a\")"),
        ("(values (make-hashmap '((\"a\" 1))))", "(1)"),
        ("(keys-values (make-hashmap '((\"a\" 1))))", "((\"a\" 1))"),
        ("(keys (make-hashmap))", "()"),
        ("(values (make-hashmap))", "()"),
        ("(keys-values (make-hashmap))", "()")
    ] as [ValueCase])
    func singleEntryEnumeration(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("every key and value is enumerated", arguments: [
        ("(length (keys \(ab)))", "2"),
        ("(length (values \(ab)))", "2"),
        ("(length (keys-values \(ab)))", "2"),
        ("(contains \"a\" (keys \(ab)))", "true"),
        ("(contains \"b\" (keys \(ab)))", "true"),
        ("(contains \"z\" (keys \(ab)))", "false"),
        ("(contains 1 (values \(ab)))", "true"),
        ("(contains 2 (values \(ab)))", "true"),
        ("(contains 3 (values \(ab)))", "false")
    ] as [ValueCase])
    func enumeration(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Equality

    @Test("equality ignores insertion order", arguments: [
        ("(eq \(ab) (make-hashmap '((\"b\" 2) (\"a\" 1))))", "true"),
        ("(eq \(ab) \(ab))", "true"),
        ("(eq (make-hashmap) (make-hashmap))", "true"),
        ("(eq \(ab) (make-hashmap '((\"a\" 1) (\"b\" 9))))", "false"),
        ("(eq \(ab) (make-hashmap '((\"a\" 1))))", "false"),
        ("(eq \(ab) (make-hashmap))", "false"),
        ("(neq \(ab) (make-hashmap '((\"a\" 1))))", "true")
    ] as [ValueCase])
    func equality(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("equality reaches into values", arguments: [
        ("(eq (make-hashmap '((\"a\" (1 2)))) (make-hashmap '((\"a\" (1 2)))))", "true"),
        ("(eq (make-hashmap '((\"a\" (1 2)))) (make-hashmap '((\"a\" (1 3)))))", "false"),
        ("(eq (make-hashmap '((1 \"a\"))) (make-hashmap '((1.0 \"a\"))))", "false")
    ] as [ValueCase])
    func nestedEquality(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a hashmap is never equal to the alist it came from")
    func notEqualToAlist() {
        expectValue("(eq \(Self.ab) (keys-values \(Self.ab)))", "false")
    }

    // MARK: Errors

    @Test("keys must be atomic and finite", arguments: [
        ("(get 'a (make-hashmap))", .invalidKey(.symbol)),
        ("(get '(1) (make-hashmap))", .invalidKey(.list)),
        ("(get (sqrt -1.0) (make-hashmap))", .invalidKey(.double)),
        ("(put (sqrt -1.0) 1 (make-hashmap))", .invalidKey(.double)),
        ("(put (pow 10.0 400.0) 1 (make-hashmap))", .invalidKey(.double)),
        ("(has-key? 'a (make-hashmap))", .invalidKey(.symbol)),
        ("(remove 'a (make-hashmap))", .invalidKey(.symbol)),
        ("(make-hashmap '((a 1)))", .invalidKey(.symbol)),
        ("(make-hashmap '(((1) 1)))", .invalidKey(.list))
    ] as [FailureCase])
    func invalidKeys(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("make-hashmap rejects a malformed alist", arguments: [
        ("(make-hashmap '(7))", .malformedAlist(0)),
        ("(make-hashmap '((1 \"a\") 7))", .malformedAlist(1)),
        ("(make-hashmap '((1)))", .malformedAlist(0)),
        ("(make-hashmap '((1 2 3)))", .malformedAlist(0)),
        ("(make-hashmap (list (list \"a\" nothing)))", .malformedAlist(0)),
        ("(make-hashmap (list (list \"a\" 1) (list \"b\" nothing)))", .malformedAlist(1))
    ] as [FailureCase])
    func malformedSource(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("make-hashmap rejects duplicate keys", arguments: [
        ("(make-hashmap '((1 \"a\") (1 \"b\")))", .duplicateKeys([0, 1])),
        ("(make-hashmap '((0 \"z\") (1 \"a\") (1 \"b\")))", .duplicateKeys([1, 2]))
    ] as [FailureCase])
    func duplicateKeys(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("make-hashmap wants a list", arguments: [
        ("(make-hashmap 7)", .unexpectedType(.integer, [.list])),
        ("(make-hashmap \"a\")", .unexpectedType(.string, [.list])),
        ("(make-hashmap (make-hashmap))", .unexpectedType(.hashmap, [.list]))
    ] as [FailureCase])
    func makeHashmapWantsAList(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("keys-values wants a hashmap", arguments: [
        ("(keys-values '())", .unexpectedType(.list, [.hashmap])),
        ("(keys-values 7)", .unexpectedType(.integer, [.hashmap]))
    ] as [FailureCase])
    func keysValuesWantsAHashmap(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("key-index is for alists only")
    func keyIndexIsAlistOnly() {
        expectFailure(
            "(key-index 1 (make-hashmap))",
            reason: .unexpectedType(.hashmap, [.list]))
    }

    @Test("a hashmap is not a sequence", arguments: [
        ("(head (make-hashmap))", .unexpectedType(.hashmap, [.list, .string])),
        ("(tail (make-hashmap))", .unexpectedType(.hashmap, [.list, .string])),
        ("(last (make-hashmap))", .unexpectedType(.hashmap, [.list, .string])),
        ("(nth 0 (make-hashmap))", .unexpectedType(.hashmap, [.list, .string])),
        ("(reverse (make-hashmap))", .unexpectedType(.hashmap, [.list, .string])),
        ("(contains 1 (make-hashmap))", .unexpectedType(.hashmap, [.list, .string])),
        ("(map (lambda (x) x) (make-hashmap))", .unexpectedType(.hashmap, [.list]))
    ] as [FailureCase])
    func notASequence(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("hashmap arity errors", arguments: [
        "(make-hashmap '() '())",
        "(keys-values)",
        "(keys-values (make-hashmap) (make-hashmap))",
        "(get \"a\")",
        "(get-or 0 \"a\")",
        "(put \"a\" 1)",
        "(remove \"a\")",
        "(has-key? \"a\")",
        "(keys)",
        "(values)"
    ])
    func arityErrors(_ source: String) {
        expectArityFailure(source)
    }

}
