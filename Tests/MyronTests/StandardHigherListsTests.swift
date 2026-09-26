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

    @Test("foldr folds from the right with an accumulator")
    func foldr() {
        expectValue("(foldr + 0 '(1 2 3 4 5))", "15")
        expectValue("(foldr * 1 '(1 2 3 4))", "24")
    }

    @Test("foldr calls the function with the element first")
    func foldrOrder() {
        expectValue("(foldr - 0 '(1 2 3))", "2")
        expectValue("(reduce - 0 '(1 2 3))", "-6")
        expectValue("(foldr cons '() '(1 2 3))", "(1 2 3)")
    }

    @Test("foldr over the empty list returns the initial value")
    func foldrEmpty() {
        expectValue("(foldr + 0 '())", "0")
    }

    @Test("foldr with a user-defined procedure")
    func foldrProcedure() {
        expectValue(
            """
            (define (keep-positive x acc) 
                (if (gt x 0) (cons x acc) acc)) (foldr keep-positive '() '(-1 2 -3 4))
            """,
            "(2 4)")
    }

    @Test("foldr over a set")
    func foldrSet() {
        expectValue("(foldr + 0 (set 1 2 3))", "6")
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
        ("(map sqrt 5)", .unexpectedType(.integer, [.list, .set])),
        ("(filter sqrt '(1.0))", .unexpectedType(.double, [.boolean])),
        ("(reduce + 0 5)", .unexpectedType(.integer, [.list, .set])),
        ("(foldr 5 0 '(1 2))", .expectedFunction(.integer)),
        ("(foldr + 0 5)", .unexpectedType(.integer, [.list, .set])),
        ("(foldr +)", .unexpectedArity(1, .exactly(3))),
        ("(all 5 '(1 2))", .expectedFunction(.integer)),
        ("(any 5 '(1 2))", .expectedFunction(.integer)),
        ("(all sqrt 5)", .unexpectedType(.integer, [.list, .set])),
        ("(any sqrt 5)", .unexpectedType(.integer, [.list, .set])),
        ("(all (lambda (x) x) '(1))", .unexpectedType(.integer, [.boolean])),
        ("(any (lambda (x) x) '(1))", .unexpectedType(.integer, [.boolean])),
        ("(all (lambda (x) x))", .unexpectedArity(1, .exactly(2)))
    ] as [FailureCase])
    func higherOrderErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
