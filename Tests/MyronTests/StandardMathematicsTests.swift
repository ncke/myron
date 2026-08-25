import Testing
@testable import Myron

// MARK: - Mathematics

@Suite("Standard Mathematics")

struct StandardMathematicsTests {

    @Test("addition", arguments: [
        ("(+ 1 2)", "3"),
        ("(+ 1 2 3 4)", "10"),
        ("(+ 0 0)", "0"),
        ("(+ -2 2)", "0"),
        ("(+ 1.0 2.5)", "3.5"),
        ("(+ 1.5 1.5 1.0)", "4.0")
    ] as [ValueCase])
    func addition(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("subtraction and negation", arguments: [
        ("(- 5 3)", "2"),
        ("(- 3 5)", "-2"),
        ("(- 5.0 3.0)", "2.0"),
        ("(- 3)", "-3"),
        ("(- -3)", "3"),
        ("(- 3.0)", "-3.0")
    ] as [ValueCase])
    func subtraction(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("multiplication", arguments: [
        ("(* 2 3)", "6"),
        ("(* 2 3 4)", "24"),
        ("(* -2 3)", "-6"),
        ("(* 1.5 2.0)", "3.0")
    ] as [ValueCase])
    func multiplication(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("division", arguments: [
        ("(/ 6 3)", "2"),
        ("(/ 7 2)", "3"),
        ("(/ 7.0 2.0)", "3.5"),
        ("(/ -6 3)", "-2")
    ] as [ValueCase])
    func division(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("square root", arguments: [
        ("(sqrt 4)", "2.0"),
        ("(sqrt 4.0)", "2.0"),
        ("(sqrt 0)", "0.0"),
        ("(sqrt 9.0)", "3.0")
    ] as [ValueCase])
    func squareRoot(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("pi is available as a constant")
    func pi() {
        expectValue("(gt pi 3.0)", "true")
        expectValue("(lt pi 4.0)", "true")
    }

    @Test("arithmetic errors", arguments: [
        ("(+ 1)", .unexpectedArity),
        ("(+ 1 2.0)", .typeMismatch),
        ("(+ 1 \"x\")", .typeMismatch),
        ("(- 1 2 3)", .unexpectedArity),
        ("(- 1 2.0)", .typeMismatch),
        ("(* 2)", .unexpectedArity),
        ("(* 1 2.0)", .typeMismatch),
        ("(/ 1 0)", .divisionByZero),
        ("(/ 1.0 0.0)", .divisionByZero),
        ("(/ 1 2.0)", .typeMismatch),
        ("(/ 1 2 3)", .unexpectedArity),
        ("(sqrt \"x\")", .typeMismatch),
        ("(sqrt 1 2)", .unexpectedArity)
    ] as [FailureCase])
    func arithmeticErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
