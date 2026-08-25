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

    @Test("logic errors", arguments: [
        ("(and true)", .unexpectedArity),
        ("(or false)", .unexpectedArity),
        ("(and true 1)", .typeMismatch),
        ("(or false \"x\")", .typeMismatch),
        ("(not 1)", .typeMismatch),
        ("(not true false)", .unexpectedArity)
    ] as [FailureCase])
    func logicErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
