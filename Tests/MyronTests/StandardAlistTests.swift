import Testing
@testable import Myron

// MARK: - Association Lists

@Suite("Standard Alist")

struct StandardAlistTests {

    @Test("get", arguments: [
        ("(get 1 '((1 \"one\") (2 \"two\")))", "\"one\""),
        ("(get 2 '((1 \"one\") (2 \"two\")))", "\"two\""),
        ("(get 3 '((1 \"one\") (2 \"two\")))", "<nothing>"),
        ("(get 1 '())", "<nothing>"),
        ("(get \"a\" '((\"a\" 1)))", "1"),
        ("(get true '((true 1)))", "1"),
        ("(get 1.5 '((1.5 1)))", "1")
    ] as [ValueCase])
    func get(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("keys are distinguished by type", arguments: [
        ("(get 1 '((1.0 \"double\") (1 \"integer\")))", "\"integer\""),
        ("(get 1.0 '((1.0 \"double\") (1 \"integer\")))", "\"double\""),
        ("(get 1 '((true \"boolean\")))", "<nothing>"),
        ("(get \"1\" '((1 \"integer\")))", "<nothing>")
    ] as [ValueCase])
    func keyTypes(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("get-or", arguments: [
        ("(get-or \"none\" 1 '((1 \"one\")))", "\"one\""),
        ("(get-or \"none\" 9 '((1 \"one\")))", "\"none\""),
        ("(get-or \"none\" 9 '())", "\"none\"")
    ] as [ValueCase])
    func getOr(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("put", arguments: [
        ("(put 2 \"two\" '((1 \"one\")))", "((1 \"one\") (2 \"two\"))"),
        ("(put 1 \"uno\" '((1 \"one\")))", "((1 \"uno\"))"),
        ("(put 1 \"one\" '())", "((1 \"one\"))"),
        ("(put 1 \"uno\" '((0 \"zero\") (1 \"one\")))", "((0 \"zero\") (1 \"uno\"))")
    ] as [ValueCase])
    func put(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("put replaces in place, leaving the original untouched")
    func putIsPure() {
        expectValue(
            "(define al '((1 \"one\"))) (put 2 \"two\" al) al",
            "((1 \"one\"))")
    }

    @Test("putting nothing removes the key", arguments: [
        ("(put 1 nothing '((1 \"one\") (2 \"two\")))", "((2 \"two\"))"),
        ("(put 9 nothing '((1 \"one\")))", "((1 \"one\"))"),
        ("(put 1 nothing '())", "()"),
        ("(put 1 (head '()) '((1 \"one\")))", "()")
    ] as [ValueCase])
    func putNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a value read back is never nothing unless the key is absent")
    func nothingIsUnstorable() {
        expectValue("(has-key? 1 (put 1 nothing '((1 \"one\"))))", "false")
    }

    @Test("remove", arguments: [
        ("(remove 1 '((1 \"one\") (2 \"two\")))", "((2 \"two\"))"),
        ("(remove 2 '((1 \"one\") (2 \"two\")))", "((1 \"one\"))"),
        ("(remove 9 '((1 \"one\")))", "((1 \"one\"))"),
        ("(remove 1 '())", "()")
    ] as [ValueCase])
    func remove(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("has-key?", arguments: [
        ("(has-key? 1 '((1 \"one\")))", "true"),
        ("(has-key? 9 '((1 \"one\")))", "false"),
        ("(has-key? 1 '())", "false")
    ] as [ValueCase])
    func hasKey(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("keys and values", arguments: [
        ("(keys '((1 \"one\") (2 \"two\")))", "(1 2)"),
        ("(values '((1 \"one\") (2 \"two\")))", "(\"one\" \"two\")"),
        ("(keys '())", "()"),
        ("(values '())", "()")
    ] as [ValueCase])
    func keysAndValues(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("key-index", arguments: [
        ("(key-index 1 '((1 \"one\") (2 \"two\")))", "0"),
        ("(key-index 2 '((1 \"one\") (2 \"two\")))", "1"),
        ("(key-index 9 '((1 \"one\")))", "<nothing>"),
        ("(key-index 1 '())", "<nothing>")
    ] as [ValueCase])
    func keyIndex(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("keys must be atomic and finite", arguments: [
        ("(get '(1) '((1 \"one\")))", .invalidKey(.list)),
        ("(get 'a '((1 \"one\")))", .invalidKey(.symbol)),
        ("(get (sqrt -1.0) '())", .invalidKey(.double)),
        ("(get (pow 10.0 400.0) '())", .invalidKey(.double)),
        ("(put (sqrt -1.0) 1 '())", .invalidKey(.double)),
        ("(keys '(((1) \"one\")))", .invalidKey(.list)),
        ("(values '(((1) \"one\")))", .invalidKey(.list))
    ] as [FailureCase])
    func invalidKeys(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("entries must be pairs", arguments: [
        ("(get 2 '((1 \"one\") 7))", .malformedAlist(1)),
        ("(get 2 '((1 \"one\") (2)))", .malformedAlist(1)),
        ("(get 2 '((1 \"one\") (2 \"two\" 3)))", .malformedAlist(1)),
        ("(keys '(7))", .malformedAlist(0)),
        ("(values '(7))", .malformedAlist(0)),
        ("(put 2 \"two\" '(7))", .malformedAlist(0))
    ] as [FailureCase])
    func malformedEntries(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a malformed entry past the match is not seen")
    func validationIsLazy() {
        expectValue("(get 1 '((1 \"one\") 7))", "\"one\"")
    }

    @Test("put rejects duplicate keys")
    func putRejectsDuplicates() {
        expectFailure(
            "(put 1 \"uno\" '((1 \"a\") (1 \"b\")))",
            reason: .duplicateKeys([0, 1]))
    }

    @Test("remove takes the first of a duplicate pair")
    func removeTakesFirst() {
        expectValue("(remove 1 '((1 \"a\") (1 \"b\")))", "((1 \"b\"))")
    }

    @Test("the alist argument must be a list", arguments: [
        ("(get 1 7)", .unexpectedType(.integer, [.list])),
        ("(keys \"a\")", .unexpectedType(.string, [.list])),
        ("(put 1 2 7)", .unexpectedType(.integer, [.list]))
    ] as [FailureCase])
    func notAList(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("alist arity errors", arguments: [
        "(get 1)",
        "(get 1 '() 3)",
        "(get-or 1 2)",
        "(put 1 2)",
        "(remove 1)",
        "(has-key? 1)",
        "(keys)",
        "(keys '() '())",
        "(values)",
        "(key-index 1)"
    ])
    func arityErrors(_ source: String) {
        expectArityFailure(source)
    }

    @Test("a round trip through put and get")
    func roundTrip() {
        expectValue(
            "(get \"b\" (put \"c\" 3 (put \"b\" 2 (put \"a\" 1 '()))))",
            "2")
    }

}
