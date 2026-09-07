import Testing
@testable import Myron

// MARK: - Logic

@Suite("Standard Logic")

struct StandardLogicTests {

    @Test("and", arguments: [
        ("(and true true)", "true"),
        ("(and true false)", "false"),
        ("(and false true)", "false"),
        ("(and true true true)", "true"),
        ("(and true false true)", "false")
    ] as [ValueCase])
    func and(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("or", arguments: [
        ("(or false false)", "false"),
        ("(or false true)", "true"),
        ("(or true false)", "true"),
        ("(or false false false)", "false"),
        ("(or false false true)", "true")
    ] as [ValueCase])
    func or(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("not", arguments: [
        ("(not true)", "false"),
        ("(not false)", "true"),
    ] as [ValueCase])
    func not(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("and and or accept a single term", arguments: [
        ("(and true)", "true"),
        ("(and false)", "false"),
        ("(or true)", "true"),
        ("(or false)", "false")
    ] as [ValueCase])
    func singleTerm(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("and and or short-circuit", arguments: [
        ("(and false (/ 1 0))", "false"),
        ("(or true (/ 1 0))", "true"),
        ("(and true false undefined)", "false"),
        ("(or false true undefined)", "true"),
        ("(define (safe-head xs) (and (not (empty? xs)) (> (head xs) 0))) (safe-head '())", "false")
    ] as [ValueCase])
    func shortCircuit(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("and and or still evaluate every term when needed", arguments: [
        ("(and true (/ 1 0))", .divisionByZero),
        ("(or false (/ 1 0))", .divisionByZero),
        ("(and true undefined)", .unrecognisedSymbol)
    ] as [FailureCase])
    func evaluatesLaterTerms(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("logic errors", arguments: [
        ("(and)", .xunexpectedArity(0, .atLeast(1))),
        ("(or)", .xunexpectedArity(0, .atLeast(1))),
        ("(and true 1)", .typeMismatch),
        ("(or false \"x\")", .typeMismatch),
        ("(and 1 (/ 1 0))", .typeMismatch),
        ("(not 1)", .typeMismatch),
        ("(not true false)", .unexpectedArity)
    ] as [FailureCase])
    func logicErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
