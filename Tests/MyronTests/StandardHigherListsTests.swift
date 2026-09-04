import Testing
@testable import Myron

// MARK: - Higher-Order Lists

@Suite("Standard Higher-Order Lists")

struct StandardHigherListsTests {

    @Test("map applies a primitive over a list")
    func mapPrimitive() {
        expectValue("(map sqrt '(1.0 4.0 9.0))", "(1.0 2.0 3.0)")
    }

    @Test("map applies a user-defined procedure")
    func mapProcedure() {
        expectValue(
            "(define (double x) (* x 2)) (map double '(1 2 3))",
            "(2 4 6)")
    }

    @Test("map over the empty list is empty")
    func mapEmpty() {
        expectValue("(map sqrt '())", "()")
    }

    @Test("filter keeps elements matching a predicate")
    func filter() {
        expectValue(
            "(define (positive x) (gt x 0)) (filter positive '(-1 2 -3 4))",
            "(2 4)")
    }

    @Test("filter over the empty list is empty")
    func filterEmpty() {
        expectValue(
            "(define (positive x) (gt x 0)) (filter positive '())",
            "()")
    }

    @Test("reduce folds with an accumulator")
    func reduce() {
        expectValue("(reduce + 0 '(1 2 3 4 5))", "15")
        expectValue("(reduce * 1 '(1 2 3 4))", "24")
    }

    @Test("reduce over the empty list returns the initial value")
    func reduceEmpty() {
        expectValue("(reduce + 0 '())", "0")
    }

    @Test("reduce with a user-defined procedure")
    func reduceProcedure() {
        expectValue(
            "(define (add a b) (+ a b)) (reduce add 0 '(10 20 30))",
            "60")
    }

    @Test("all is true when every element satisfies the predicate")
    func all() {
        expectValue("(all (lambda (x) (> x 0)) '(1 2 3))", "true")
        expectValue("(all (lambda (x) (> x 1)) '(1 2 3))", "false")
    }

    @Test("all over the empty list is true")
    func allEmpty() {
        expectValue("(all (lambda (x) (> x 0)) '())", "true")
    }

    @Test("any is true when some element satisfies the predicate")
    func any() {
        expectValue("(any (lambda (x) (> x 2)) '(1 2 3))", "true")
        expectValue("(any (lambda (x) (> x 9)) '(1 2 3))", "false")
    }

    @Test("any over the empty list is false")
    func anyEmpty() {
        expectValue("(any (lambda (x) (> x 0)) '())", "false")
    }

    @Test("all and any accept a named procedure")
    func allAnyProcedure() {
        expectValue(
            "(define (positive x) (gt x 0)) (all positive '(1 2 3))",
            "true")
        expectValue(
            "(define (positive x) (gt x 0)) (any positive '(-1 -2 3))",
            "true")
    }

    @Test("all and any reject a non-function even over the empty list")
    func allAnyRejectNonFunction() {
        expectFailure("(all 5 '())", reason: .expectedFunction(.integer))
        expectFailure("(any 5 '())", reason: .expectedFunction(.integer))
    }

    @Test("higher-order errors", arguments: [
        ("(map 5 '(1 2))", .expectedFunction(.integer)),
        ("(map sqrt 5)", .expectedList),
        ("(filter sqrt '(1.0))", .typeMismatch),
        ("(reduce + 0 5)", .expectedList),
        ("(all 5 '(1 2))", .expectedFunction(.integer)),
        ("(any 5 '(1 2))", .expectedFunction(.integer)),
        ("(all sqrt 5)", .expectedList),
        ("(any sqrt 5)", .expectedList),
        ("(all (lambda (x) x) '(1))", .typeMismatch),
        ("(any (lambda (x) x) '(1))", .typeMismatch),
        ("(all (lambda (x) x))", .unexpectedArity)
    ] as [FailureCase])
    func higherOrderErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
