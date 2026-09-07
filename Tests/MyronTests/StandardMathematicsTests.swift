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
        ("(+ 1)", .unexpectedArity(1, .atLeast(2))),
        ("(+ 1 2.0)", .unexpectedType(.double, [.integer])),
        ("(+ 1 \"x\")", .unexpectedType(.string, [.integer])),
        ("(- 1 2 3)", .unexpectedArity(3, .exactly(2))),
        ("(- 1 2.0)", .unexpectedType(.integer, [.double, .integer])),
        ("(* 2)", .unexpectedArity(1, .atLeast(2))),
        ("(* 1 2.0)", .unexpectedType(.double, [.integer])),
        ("(/ 1 0)", .divisionByZero),
        ("(/ 1.0 0.0)", .divisionByZero),
        ("(/ 1 2.0)", .unexpectedType(.integer, [.double, .integer])),
        ("(/ 1 2 3)", .unexpectedArity(3, .exactly(2))),
        ("(sqrt \"x\")", .unexpectedType(.string, [.double, .integer])),
        ("(sqrt 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(rem 5 0)", .divisionByZero),
        ("(mod 5 0)", .divisionByZero)
    ] as [FailureCase])
    func arithmeticErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("power", arguments: [
        ("(pow 2 3)", "8"),
        ("(pow 2.0 3.0)", "8.0"),
        ("(pow 2 -1)", "0"),
        ("(pow 5 0)", "1"),
        ("(pow 0 0)", "1"),
        ("(pow 0 5)", "0"),
        ("(pow -2 3)", "-8"),
        ("(pow -2 4)", "16"),
        ("(pow 1 -5)", "1"),
        ("(pow -1 -5)", "-1"),
        ("(pow -1 -4)", "1"),
        ("(pow 10 18)", "1000000000000000000"),
        ("(pow 2 62)", "4611686018427387904"),
        ("(pow -2 63)", "-9223372036854775808")
    ] as [ValueCase])
    func power(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("modulo is floored", arguments: [
        ("(mod 7 3)", "1"),
        ("(mod 6 3)", "0"),
        ("(mod -7 -3)", "-1"),
        ("(mod -7 3)", "2"),
        ("(mod 7 -3)", "-2"),
        ("(mod -6 3)", "0"),
        ("(mod 6 -3)", "0"),
        ("(mod 0 3)", "0"),
        ("(mod 0 -3)", "0")
    ] as [ValueCase])
    func modulo(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("remainder truncates toward zero", arguments: [
        ("(rem 7 3)", "1"),
        ("(rem 7 -3)", "1"),
        ("(rem -7 3)", "-1"),
        ("(rem -7 -3)", "-1"),
        ("(rem -6 3)", "0"),
        ("(rem 0 3)", "0")
    ] as [ValueCase])
    func remainder(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("remainder errors", arguments: [
        ("(rem 5 0)", .divisionByZero),
        ("(rem 5)", .unexpectedArity(1, .exactly(2))),
        ("(rem 5.0 2.0)", .unexpectedType(.double, [.integer])),
        ("(rem 5 2.0)", .unexpectedType(.double, [.integer]))
    ] as [FailureCase])
    func remainderErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("integer arithmetic reaches the limits without overflowing", arguments: [
        ("(+ 9223372036854775806 1)", "9223372036854775807"),
        ("(- -9223372036854775807 1)", "-9223372036854775808"),
        ("(* -4611686018427387904 2)", "-9223372036854775808"),
        ("(* 4611686018427387903 2)", "9223372036854775806"),
        ("(/ -9223372036854775808 1)", "-9223372036854775808"),
        ("(/ -9223372036854775808 2)", "-4611686018427387904"),
        ("(- 9223372036854775807)", "-9223372036854775807"),
        ("(abs -9223372036854775807)", "9223372036854775807"),
        ("(mod 9223372036854775807 2)", "1"),
        ("(mod -9223372036854775808 3)", "1"),
        ("(mod -9223372036854775808 -1)", "0"),
        ("(rem -9223372036854775808 -1)", "0"),
        ("(rem -9223372036854775808 3)", "-2"),
        ("(min -9223372036854775808 9223372036854775807)", "-9223372036854775808"),
        ("(max -9223372036854775808 9223372036854775807)", "9223372036854775807")
    ] as [ValueCase])
    func integerLimits(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("integer overflow is an error rather than a crash", arguments: [
        ("(+ 9223372036854775807 1)", .overflow),
        ("(+ 1 1 9223372036854775807)", .overflow),
        ("(+ -9223372036854775808 -1)", .overflow),
        ("(- -9223372036854775808 1)", .overflow),
        ("(- 9223372036854775807 -1)", .overflow),
        ("(* 9223372036854775807 2)", .overflow),
        ("(* 2 2 4611686018427387904)", .overflow),
        ("(* 4611686018427387904 2)", .overflow),
        ("(* -9223372036854775808 -1)", .overflow),
        ("(/ -9223372036854775808 -1)", .overflow),
        ("(- -9223372036854775808)", .overflow),
        ("(abs -9223372036854775808)", .overflow),
        ("(pow 2 63)", .overflow),
        ("(pow 2 64)", .overflow),
        ("(pow 2 1024)", .overflow),
        ("(pow -2 64)", .overflow),
        ("(pow 3 40)", .overflow),
        ("(pow 0 -1)", .divisionByZero),
        ("(integer 9223372036854775807.0)", .invalidNumber)
    ] as [FailureCase])
    func integerOverflow(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("an integer literal beyond the machine range is an invalid number", arguments: [
        "9223372036854775808",
        "-9223372036854775809"
    ])
    func integerLiteralRange(_ source: String) {
        expectFailure(source, reason: .invalidNumber)
    }

    @Test("double arithmetic does not overflow to an error")
    func doubleArithmeticSaturates() {
        expectValue("(* 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0 1000000000000000000.0)", "inf")
    }

    @Test("casts to integer", arguments: [
        ("(integer -20.0)", "-20"),
        ("(integer 10.0)", "10"),
        ("(integer 238.9)", "238"),
        ("(integer 238.2)", "238"),
        ("(integer 0.0)", "0"),
        ("(integer -85.8)", "-85"),
        ("(integer -85.2)", "-85"),
        ("(integer -77)", "-77"),
        ("(integer 77)", "77")
    ] as [ValueCase])
    func castsToInteger(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("casts to double", arguments: [
        ("(double -20)", "-20.0"),
        ("(double 10)", "10.0"),
        ("(double 0.0)", "0.0"),
        ("(double -85.8)", "-85.8"),
        ("(double -85.2)", "-85.2")
    ] as [ValueCase])
    func castsToDouble(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("casts parse strings", arguments: [
        ("(integer \"42\")", "42"),
        ("(integer \"-42\")", "-42"),
        ("(integer \"+42\")", "42"),
        ("(integer \"0\")", "0"),
        ("(integer \"42.9\")", "42"),
        ("(integer \"-42.9\")", "-42"),
        ("(integer \"1e3\")", "1000"),
        ("(integer \"9223372036854775807\")", "9223372036854775807"),
        ("(integer \"-9223372036854775808\")", "-9223372036854775808"),
        ("(integer \"9007199254740993\")", "9007199254740993"),
        ("(double \"1.5\")", "1.5"),
        ("(double \"-1.5\")", "-1.5"),
        ("(double \"42\")", "42.0"),
        ("(double \"1e3\")", "1000.0"),
        ("(double \"0\")", "0.0"),
        ("(integer \" 42\")", "42"),
        ("(double \" 1.5\")", "1.5")
    ] as [ValueCase])
    func castsFromStrings(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("casts round-trip through string")
    func castsRoundTrip() {
        expectValue("(integer (string 42))", "42")
        expectValue("(double (string 1.5))", "1.5")
        expectValue("(integer (string -9223372036854775808))", "-9223372036854775808")
    }

    @Test("cast errors", arguments: [
        ("(integer \"abc\")", .invalidNumber),
        ("(integer \"\")", .invalidNumber),
        ("(integer \"42abc\")", .invalidNumber),
        ("(integer \"1.2.3\")", .invalidNumber),
        ("(integer \"nan\")", .invalidNumber),
        ("(integer \"inf\")", .invalidNumber),
        ("(integer \"9223372036854775808\")", .invalidNumber),
        ("(integer \"1e19\")", .invalidNumber),
        ("(double \"abc\")", .invalidNumber),
        ("(double \"\")", .invalidNumber),
        ("(integer true)", .typeCastFailed(.boolean, .integer)),
        ("(integer '(1))", .typeCastFailed(.list, .integer)),
        ("(double true)", .typeCastFailed(.boolean, .double)),
        ("(double '(1))", .typeCastFailed(.list, .double)),
        ("(integer)", .unexpectedArity(0, .exactly(1))),
        ("(integer 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(double)", .unexpectedArity(0, .exactly(1))),
        ("(double 1 2)", .unexpectedArity(2, .exactly(1)))
    ] as [FailureCase])
    func castErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
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
        ("(pow 2)", .unexpectedArity(1, .exactly(2))),
        ("(pow 2 \"x\")", .unexpectedType(.integer, [.double, .integer])),
        ("(mod 7.0 3.0)", .unexpectedType(.double, [.integer])),
        ("(min)", .unexpectedArity(0, .atLeast(1))),
        ("(min 1 2.0)", .unexpectedType(.double, [.integer])),
        ("(floor 3)", .unexpectedType(.integer, [.double])),
        ("(round 3)", .unexpectedType(.integer, [.double])),
        ("(log 100)", .unexpectedType(.integer, [.double])),
        ("(sin 0)", .unexpectedType(.integer, [.double])),
        ("(atan2 1.0)", .unexpectedArity(1, .exactly(2)))
    ] as [FailureCase])
    func extendedErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
