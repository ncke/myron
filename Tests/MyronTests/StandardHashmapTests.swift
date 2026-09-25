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

    private static let point = "(define point (make-record-type 'point '(x y)))"

    @Test("make-hashmap over a record keys each field by its symbol", arguments: [
        (point + " (eq (make-hashmap (make-record point 1 2)) (make-hashmap '((x 1) (y 2))))",
         "true"),
        (point + " (get 'x (make-hashmap (make-record point 1 2)))", "1"),
        (point + " (get \"x\" (make-hashmap (make-record point 1 2)))", "<nothing>"),
        (point + " (length (make-hashmap (make-record point '(1) (make-record point 1 2))))",
         "2"),
        ("(empty? (make-hashmap (make-record (make-record-type 'unit '()))))", "true"),
        (point + " (nan? (get 'x (make-hashmap (make-record point (sqrt -1.0) 2))))", "true")
    ] as [ValueCase])
    func makeHashmapFromRecord(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // A hashmap never holds nothing as a value, so a field holding nothing is
    // left out, just as `put` with nothing removes the key.
    @Test("make-hashmap over a record leaves out a field holding nothing", arguments: [
        (point + " (length (make-hashmap (make-record point nothing 2)))", "1"),
        (point + " (has-key? 'x (make-hashmap (make-record point nothing 2)))", "false"),
        (point + " (eq (make-hashmap (make-record point nothing 2)) (make-hashmap '((y 2))))",
         "true"),
        (point + " (empty? (make-hashmap (make-record point nothing nothing)))", "true")
    ] as [ValueCase])
    func makeHashmapFromRecordSkipsNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a record and its hashmap hold the same fields")
    func recordRoundTrip() {
        let p = Self.point + " (define p (make-record point 1 2))"
        let fields = "(make-set (keys-values p))"
        expectValue(p + " (eq (make-set (keys-values (make-hashmap p))) \(fields))", "true")
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
        ("(get 'a (make-hashmap '((\"a\" \"string\"))))", "<nothing>"),
        ("(get \"a\" (make-hashmap '((a \"symbol\"))))", "<nothing>"),
        ("(get '(1) (make-hashmap '((1 \"integer\"))))", "<nothing>"),
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
        ("(contains? \"a\" (keys \(ab)))", "true"),
        ("(contains? \"b\" (keys \(ab)))", "true"),
        ("(contains? \"z\" (keys \(ab)))", "false"),
        ("(contains? 1 (values \(ab)))", "true"),
        ("(contains? 2 (values \(ab)))", "true"),
        ("(contains? 3 (values \(ab)))", "false")
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

    // MARK: Keys

    // Any value is a key now that `MyronKey` has gone, so the kinds that were
    // once rejected have to round trip like any other.
    @Test("a key may be of any kind", arguments: [
        ("(get 'a (make-hashmap '((a 1))))", "1"),
        ("(get '(1 2) (make-hashmap '(((1 2) \"x\"))))", "\"x\""),
        ("(get true (make-hashmap '((true 1))))", "1"),
        ("(get nothing (put nothing 1 (make-hashmap)))", "1"),
        ("(get (make-hashmap '((\"a\" 1))) (put (make-hashmap '((\"a\" 1))) 2 (make-hashmap)))", "2"),
        ("(get + (put + 1 (make-hashmap)))", "1"),
        ("(get map (put map 1 (make-hashmap)))", "1")
    ] as [ValueCase])
    func keysOfAnyKind(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a structural key answers the rest of the operations", arguments: [
        ("(has-key? '(1 2) (make-hashmap '(((1 2) \"x\"))))", "true"),
        ("(has-key? '(1 3) (make-hashmap '(((1 2) \"x\"))))", "false"),
        ("(remove '(1 2) (make-hashmap '(((1 2) \"x\"))))", "#()"),
        ("(keys (make-hashmap '(((1 2) \"x\"))))", "((1 2))"),
        ("(length (put '(1 2) \"y\" (make-hashmap '(((1 2) \"x\")))))", "1"),
        ("(get-or 0 '(9) (make-hashmap '(((1 2) \"x\"))))", "0")
    ] as [ValueCase])
    func structuralKeyOperations(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // A `nan` is not equal to itself, and neither is anything holding one, so
    // an entry under such a key could never be found again. It is dropped.
    @Test("a key holding a nan is dropped", arguments: [
        ("(put (sqrt -1.0) 1 (make-hashmap))", "#()"),
        ("(put (list 1 (sqrt -1.0)) 1 (make-hashmap))", "#()"),
        ("(put (list (list (list (sqrt -1.0)))) 1 (make-hashmap))", "#()"),
        ("(put (make-hashmap (list (list \"k\" (sqrt -1.0)))) 1 (make-hashmap))", "#()"),
        ("(length (put (sqrt -1.0) 2 (put (sqrt -1.0) 1 (make-hashmap))))", "0"),
        ("(length (put (list 1 (sqrt -1.0)) 2 (put (list 1 (sqrt -1.0)) 1 (make-hashmap))))", "0"),
        ("(make-hashmap (list (list (sqrt -1.0) 1)))", "#()"),
        ("(length (make-hashmap (list (list (sqrt -1.0) 1) (list \"a\" 2))))", "1"),
        ("(has-key? (sqrt -1.0) (put (sqrt -1.0) 1 (make-hashmap)))", "false"),
        ("(get (sqrt -1.0) (put (sqrt -1.0) 1 (make-hashmap)))", "<nothing>")
    ] as [ValueCase])
    func nanKeyDropped(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // An infinity equals itself, so it is a perfectly good key.
    @Test("a key holding an infinity is kept", arguments: [
        ("(get (pow 10.0 400.0) (put (pow 10.0 400.0) 1 (make-hashmap)))", "1"),
        ("(get (list 1 (pow 10.0 400.0)) (put (list 1 (pow 10.0 400.0)) 1 (make-hashmap)))", "1"),
        ("(length (put (pow 10.0 400.0) 2 (put (pow 10.0 400.0) 1 (make-hashmap))))", "1"),
        ("(has-key? (pow 10.0 400.0) (put (pow 10.0 400.0) 1 (make-hashmap)))", "true")
    ] as [ValueCase])
    func infiniteKeyKept(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // Only keys are restricted: a list holds whatever the user puts in it, and
    // a nan is fine as a value.
    @Test("a nan is fine everywhere but a key", arguments: [
        ("(get \"a\" (put \"a\" (sqrt -1.0) (make-hashmap)))", "nan"),
        ("(head (list (sqrt -1.0) 1))", "nan"),
        ("(length (list (sqrt -1.0) (pow 10.0 400.0)))", "2"),
        ("(get \"a\" (put \"a\" (list 1 (sqrt -1.0)) (make-hashmap)))", "(1 nan)")
    ] as [ValueCase])
    func nanOutsideAKey(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("dropping a key leaves the rest of the hashmap alone")
    func droppedKeyLeavesTheRest() {
        expectValue(
            "(get \"a\" (put (sqrt -1.0) 1 (make-hashmap '((\"a\" 2)))))",
            "2")
    }

    // MARK: Errors

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

    @Test("make-hashmap wants a list or record", arguments: [
        ("(make-hashmap 7)", .unexpectedType(.integer, [.list, .record])),
        ("(make-hashmap \"a\")", .unexpectedType(.string, [.list, .record])),
        ("(make-hashmap (make-hashmap))", .unexpectedType(.hashmap, [.list, .record])),
    ] as [FailureCase])
    func makeHashmapWantsAList(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("keys-values wants a hashmap", arguments: [
        ("(keys-values '())", .unexpectedType(.list, [.hashmap, .record])),
        ("(keys-values 7)", .unexpectedType(.integer, [.hashmap, .record]))
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
        ("(contains? 1 (make-hashmap))", .unexpectedType(.hashmap, [.list, .string, .set])),
        ("(map (lambda (x) x) (make-hashmap))", .unexpectedType(.hashmap, [.list, .set]))
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
