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

    @Test("power", arguments: [
        ("(pow 2 3)", "8"),
        ("(pow 2.0 3.0)", "8.0"),
        ("(pow 2 -1)", "0"),
        ("(pow 5 0)", "1")
    ] as [ValueCase])
    func power(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("modulo is floored", arguments: [
        ("(mod 7 3)", "1"),
        ("(mod 6 3)", "0"),
        ("(mod -7 3)", "2"),
        ("(mod 7 -3)", "-2"),
        ("(mod 5 0)", "5")
    ] as [ValueCase])
    func modulo(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("minimum and maximum", arguments: [
        ("(min 3 1 2)", "1"),
        ("(max 3 1 2)", "3"),
        ("(min 5)", "5"),
        ("(max 1.5 2.5 0.5)", "2.5"),
        ("(min -1 -2 -3)", "-3")
    ] as [ValueCase])
    func minMax(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("floor, ceil, round", arguments: [
        ("(floor 3.7)", "3.0"),
        ("(floor -1.5)", "-2.0"),
        ("(ceil 3.2)", "4.0"),
        ("(ceil -1.5)", "-1.0"),
        ("(round 3.5)", "4.0"),
        ("(round -2.5)", "-3.0"),
        ("(round 2.4)", "2.0")
    ] as [ValueCase])
    func rounding(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("absolute value", arguments: [
        ("(abs -5)", "5"),
        ("(abs 5)", "5"),
        ("(abs -5.0)", "5.0"),
        ("(abs 0)", "0")
    ] as [ValueCase])
    func absoluteValue(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("logarithms and trigonometry", arguments: [
        ("(ln 1.0)", "0.0"),
        ("(log 1.0)", "0.0"),
        ("(sin 0.0)", "0.0"),
        ("(cos 0.0)", "1.0"),
        ("(tan 0.0)", "0.0"),
        ("(asin 0.0)", "0.0"),
        ("(acos 1.0)", "0.0"),
        ("(atan 0.0)", "0.0"),
        ("(atan2 0.0 1.0)", "0.0")
    ] as [ValueCase])
    func transcendental(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("extended arithmetic errors", arguments: [
        ("(pow 2)", .unexpectedArity),
        ("(pow 2 \"x\")", .typeMismatch),
        ("(mod 7.0 3.0)", .typeMismatch),
        ("(min)", .unexpectedArity),
        ("(min 1 2.0)", .typeMismatch),
        ("(floor 3)", .typeMismatch),
        ("(round 3)", .typeMismatch),
        ("(log 100)", .typeMismatch),
        ("(sin 0)", .typeMismatch),
        ("(atan2 1.0)", .unexpectedArity)
    ] as [FailureCase])
    func extendedErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
