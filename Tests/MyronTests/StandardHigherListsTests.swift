import Testing
@testable import Myron

// MARK: - Higher-Order Lists

@Suite("Standard Higher-Order Lists")
struct StandardHigherListsTests {

    @Test("map applies a primitive over a list")
    func mapPrimitive() {
        expectValue("(map sqrt (quote (1.0 4.0 9.0)))", "(1.0 2.0 3.0)")
    }

    @Test("map applies a user-defined procedure")
    func mapProcedure() {
        expectValue(
            "(define (double x) (* x 2)) (map double (quote (1 2 3)))",
            "(2 4 6)")
    }

    @Test("map over the empty list is empty")
    func mapEmpty() {
        expectValue("(map sqrt (quote ()))", "()")
    }

    @Test("filter keeps elements matching a predicate")
    func filter() {
        expectValue(
            "(define (positive x) (gt x 0)) (filter positive (quote (-1 2 -3 4)))",
            "(2 4)")
    }

    @Test("filter over the empty list is empty")
    func filterEmpty() {
        expectValue(
            "(define (positive x) (gt x 0)) (filter positive (quote ()))",
            "()")
    }

    @Test("reduce folds with an accumulator")
    func reduce() {
        expectValue("(reduce + 0 (quote (1 2 3 4 5)))", "15")
        expectValue("(reduce * 1 (quote (1 2 3 4)))", "24")
    }

    @Test("reduce over the empty list returns the initial value")
    func reduceEmpty() {
        expectValue("(reduce + 0 (quote ()))", "0")
    }

    @Test("reduce with a user-defined procedure")
    func reduceProcedure() {
        expectValue(
            "(define (add a b) (+ a b)) (reduce add 0 (quote (10 20 30)))",
            "60")
    }

    @Test("higher-order errors", arguments: [
        ("(map 5 (quote (1 2)))", .expectedFunction("integer")),
        ("(map sqrt 5)", .expectedList),
        ("(filter sqrt (quote (1.0)))", .typeMismatch),
        ("(reduce + 0 5)", .expectedList)
    ] as [FailureCase])
    func higherOrderErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
