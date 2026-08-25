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
        ("(eq (quote a) (quote a))", "true"),
        ("(eq (quote a) (quote b))", "false"),
        ("(eq (quote (1 2 3)) (quote (1 2 3)))", "true"),
        ("(eq (quote (1 2)) (quote (1 3)))", "false"),
        ("(eq (quote (1 2)) (quote (1 2 3)))", "false"),
        ("(eq (quote ((1) (2))) (quote ((1) (2))))", "true")
    ] as [ValueCase])
    func equality(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("inequality", arguments: [
        ("(neq 1 2)", "true"),
        ("(neq 1 1)", "false"),
        ("(!= 1 2)", "true")
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
        ("(>= 3 3)", "true")
    ] as [ValueCase])
    func greaterThanOrEqual(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("less than", arguments: [
        ("(lt 2 3)", "true"),
        ("(lt 3 2)", "false"),
        ("(lt 2 2)", "false"),
        ("(< 2 3)", "true"),
        ("(lt \"a\" \"b\")", "true")
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

    @Test("comparison errors", arguments: [
        ("(eq 1)", .unexpectedArity),
        ("(eq 1 1.0)", .typeMismatch),
        ("(eq (quote (1)) (quote (1.0)))", .typeMismatch),
        ("(gt 1)", .unexpectedArity),
        ("(gt 1 1.0)", .typeMismatch),
        ("(gt true false)", .incomparableTypes)
    ] as [FailureCase])
    func comparisonErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("comparing nothing is inequatable")
    func comparingNothing() {
        expectFailure(
            "(eq (head (quote ())) (head (quote ())))",
            reason: .inequatableTypes)
    }

}
