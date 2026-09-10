import Testing
@testable import Myron

// MARK: - Predicates

@Suite("Standard Predicates")

struct StandardPredicatesTests {

    @Test("nothing?", arguments: [
        ("(nothing? (head '()))", "true"),
        ("(nothing? (last '()))", "true"),
        ("(nothing? 1)", "false"),
        ("(nothing? '())", "false"),
        ("(nothing? nothing)", "true")
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

    @Test("positive?", arguments: [
        ("(positive? 0)", "false"),
        ("(positive? -1)", "false"),
        ("(positive? 1)", "true"),
        ("(positive? 0.0)", "false"),
        ("(positive? -1.0)", "false"),
        ("(positive? 1.0)", "true")
    ] as [ValueCase])
    func isPositive(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("negative?", arguments: [
        ("(negative? 0)", "false"),
        ("(negative? -1)", "true"),
        ("(negative? 1)", "false"),
        ("(negative? 0.0)", "false"),
        ("(negative? -1.0)", "true"),
        ("(negative? 1.0)", "false")
    ] as [ValueCase])
    func isNegative(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("zero?", arguments: [
        ("(zero? 0)", "true"),
        ("(zero? -1)", "false"),
        ("(zero? 1)", "false"),
        ("(zero? 0.0)", "true"),
        ("(zero? -0.0)", "true"),
        ("(zero? -1.0)", "false"),
        ("(zero? 1.0)", "false")
    ] as [ValueCase])
    func isZero(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("predicates are false for functions rather than failing")
    func predicatesOverFunctions() {
        expectValue("(list? sqrt)", "false")
        expectValue("(number? sqrt)", "false")
        expectValue("(positive? sqrt)", "false")
        expectValue("(negative? sqrt)", "false")
        expectValue("(zero? sqrt)", "false")
    }

    @Test("sign predicates are false for non-numbers rather than failing", arguments: [
        ("(positive? \"1\")", "false"),
        ("(negative? \"-1\")", "false"),
        ("(zero? \"0\")", "false"),
        ("(positive? true)", "false"),
        ("(zero? '())", "false"),
        ("(zero? (head '()))", "false")
    ] as [ValueCase])
    func signPredicatesOverNonNumbers(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("sign predicates partition the integers", arguments: [
        ("(positive? 9223372036854775807)", "true"),
        ("(negative? -9223372036854775808)", "true"),
        ("(zero? (- 5 5))", "true"),
        ("(or (positive? 3) (negative? 3) (zero? 3))", "true"),
        ("(and (not (positive? 0)) (not (negative? 0)))", "true")
    ] as [ValueCase])
    func signPredicatesPartition(_ c: ValueCase) {
        expectValue(c.source, c.expected)
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

    @Test("finite?", arguments: [
        ("(finite? 1.0)", "true"),
        ("(finite? 1)", "true"),
        ("(finite? (sqrt -1.0))", "false"),
        ("(finite? (pow 10.0 400.0))", "false"),
        ("(finite? \"a\")", "false"),
        ("(finite? '(1))", "false")
    ] as [ValueCase])
    func isFinite(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("infinite?", arguments: [
        ("(infinite? (pow 10.0 400.0))", "true"),
        ("(infinite? 1.0)", "false"),
        ("(infinite? 1)", "false"),
        ("(infinite? (sqrt -1.0))", "false"),
        ("(infinite? \"a\")", "false")
    ] as [ValueCase])
    func isInfinite(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("predicate errors", arguments: [
        ("(nothing? 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(number?)", .unexpectedArity(0, .exactly(1))),
        ("(integer? 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(list? 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(positive? 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(negative? 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(zero? 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(finite? 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(infinite?)", .unexpectedArity(0, .exactly(1)))
    ] as [FailureCase])
    func predicateErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
