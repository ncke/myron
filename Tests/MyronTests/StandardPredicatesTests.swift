import Testing
@testable import Myron

// MARK: - Predicates

@Suite("Standard Predicates")

struct StandardPredicatesTests {

    @Test("nothing?", arguments: [
        ("(nothing? (head '()))", "true"),
        ("(nothing? (last '()))", "true"),
        ("(nothing? 1)", "false"),
        ("(nothing? '())", "false")
    ] as [ValueCase])
    func isNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("number?", arguments: [
        ("(number? 1)", "true"),
        ("(number? 1.0)", "true"),
        ("(number? \"a\")", "false"),
        ("(number? '(1))", "false")
    ] as [ValueCase])
    func isNumber(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("integer?", arguments: [
        ("(integer? 1)", "true"),
        ("(integer? 1.0)", "false"),
        ("(integer? true)", "false")
    ] as [ValueCase])
    func isInteger(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("double?", arguments: [
        ("(double? 1.0)", "true"),
        ("(double? 1)", "false"),
        ("(double? pi)", "true")
    ] as [ValueCase])
    func isDouble(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("string?", arguments: [
        ("(string? \"a\")", "true"),
        ("(string? 1)", "false")
    ] as [ValueCase])
    func isString(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("boolean?", arguments: [
        ("(boolean? true)", "true"),
        ("(boolean? false)", "true"),
        ("(boolean? 1)", "false")
    ] as [ValueCase])
    func isBoolean(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("list?", arguments: [
        ("(list? '(1))", "true"),
        ("(list? '())", "true"),
        ("(list? 1)", "false")
    ] as [ValueCase])
    func isList(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("predicates are false for functions rather than failing")
    func predicatesOverFunctions() {
        expectValue("(list? sqrt)", "false")
        expectValue("(number? sqrt)", "false")
    }

    @Test("nothing? makes an empty head observable")
    func nothingIsObservable() {
        expectValue(
            """
            (define (safe-head xs) (if (empty? xs) 0 (head xs)))
            (safe-head '())
            """,
            "0")
    }

    @Test("predicate errors", arguments: [
        ("(nothing? 1 2)", .unexpectedArity),
        ("(number?)", .unexpectedArity),
        ("(integer? 1 2)", .unexpectedArity),
        ("(list? 1 2)", .unexpectedArity)
    ] as [FailureCase])
    func predicateErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
