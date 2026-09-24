import Testing
@testable import Myron

// MARK: - Comparison

@Suite("Standard Comparison")

struct StandardComparisonTests {

    @Test("equality", arguments: [
        ("(eq 1 1)", "true"),
        ("(eq 1 2)", "false"),
        ("(== 1 1)", "true"),
        ("(eq 1.5 1.5)", "true"),
        ("(eq true true)", "true"),
        ("(eq true false)", "false"),
        ("(eq \"a\" \"a\")", "true"),
        ("(eq \"a\" \"b\")", "false"),
        ("(eq 'a 'a)", "true"),
        ("(eq 'a 'b)", "false"),
        ("(eq '(1 2 3) '(1 2 3))", "true"),
        ("(eq '(1 2) '(1 3))", "false"),
        ("(eq '(1 2) '(1 2 3))", "false"),
        ("(eq '((1) (2)) '((1) (2)))", "true"),
        ("(eq 1 1.0)", "false"),
        ("(eq '(1) '(1.0))", "false"),
        ("(eq true 1)", "false"),
        ("(eq nothing nothing)", "true"),
        ("(eq nothing 1)", "false")
    ] as [ValueCase])
    func equality(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("inequality", arguments: [
        ("(neq 1 2)", "true"),
        ("(neq 1 1)", "false"),
        ("(!= 1 2)", "true"),
        ("(neq 1 1.0)", "true")
    ] as [ValueCase])
    func inequality(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("greater than", arguments: [
        ("(gt 3 2)", "true"),
        ("(gt 2 3)", "false"),
        ("(gt 2 2)", "false"),
        ("(> 3 2)", "true"),
        ("(gt 3.0 2.0)", "true"),
        ("(gt \"b\" \"a\")", "true"),
        ("(gt \"a\" \"b\")", "false")
    ] as [ValueCase])
    func greaterThan(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("greater than or equal", arguments: [
        ("(gte 3 2)", "true"),
        ("(gte 3 3)", "true"),
        ("(gte 2 3)", "false"),
        ("(>= 3 3)", "true"),
        ("(gte 2.5 2.5)", "true"),
        ("(gte 2.0 2.5)", "false"),
        ("(gte \"b\" \"a\")", "true"),
        ("(gte \"a\" \"a\")", "true"),
        ("(gte \"a\" \"b\")", "false")
    ] as [ValueCase])
    func greaterThanOrEqual(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("less than", arguments: [
        ("(lt 2 3)", "true"),
        ("(lt 3 2)", "false"),
        ("(lt 2 2)", "false"),
        ("(< 2 3)", "true"),
        ("(lt \"a\" \"b\")", "true"),
        ("(lt \"b\" \"a\")", "false"),
        ("(lt \"a\" \"a\")", "false"),
        ("(lt 1.0 2.0)", "true"),
        ("(lt 2.0 2.0)", "false")
    ] as [ValueCase])
    func lessThan(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("less than or equal", arguments: [
        ("(lte 2 3)", "true"),
        ("(lte 3 3)", "true"),
        ("(lte 3 2)", "false"),
        ("(<= 3 3)", "true")
    ] as [ValueCase])
    func lessThanOrEqual(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a nan orders after every other double", arguments: [
        ("(lt 1.0 nan)", "true"),
        ("(lt nan 1.0)", "false"),
        ("(gt nan 1.0)", "true"),
        ("(gt 1.0 nan)", "false"),
        ("(gte nan 1.0)", "true"),
        ("(gte 1.0 nan)", "false"),
        ("(lte nan 1.0)", "false"),
        ("(lte 1.0 nan)", "true"),
        ("(lt infinity nan)", "true"),
        ("(gt nan infinity)", "true")
    ] as [ValueCase])
    func orderingNaN(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a nan is neither less nor greater than a nan", arguments: [
        ("(lt nan nan)", "false"),
        ("(gt nan nan)", "false"),
        ("(lte nan nan)", "true"),
        ("(gte nan nan)", "true"),
        ("(eq nan nan)", "false")
    ] as [ValueCase])
    func orderingNaNAgainstItself(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("comparison errors", arguments: [
        ("(eq 1)", .unexpectedArity(1, .exactly(2))),
        ("(gt 1)", .unexpectedArity(1, .exactly(2))),
        ("(gt 1 1.0)", .unexpectedType(.double, [.integer])),
        ("(gt true false)", .incomparableTypes),
        ("(lt 1)", .unexpectedArity(1, .exactly(2))),
        ("(lt 1 1.0)", .unexpectedType(.double, [.integer])),
        ("(lt true false)", .incomparableTypes),
        ("(gte 1 1.0)", .unexpectedType(.double, [.integer])),
        ("(gte '(1) '(1))", .incomparableTypes)
    ] as [FailureCase])
    func comparisonErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("nothing is equal only to itself", arguments: [
        ("(eq (head '()) (head '()))", "true"),
        ("(eq (head '()) nothing)", "true"),
        ("(eq (head '()) 1)", "false"),
        ("(neq (head '()) 1)", "true")
    ] as [ValueCase])
    func comparingNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a callable compares equal to itself", arguments: [
        ("(eq eq eq)", "true"),
        ("(eq map map)", "true"),
        ("(eq map filter)", "false"),
        ("(eq all any)", "false")
    ] as [ValueCase])
    func comparingProcedures(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

}
