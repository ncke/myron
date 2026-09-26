import Testing
@testable import Myron

// MARK: - Lists

@Suite("Standard Lists")

struct StandardListsTests {

    @Test("head", arguments: [
        ("(head '(1 2 3))", "1"),
        ("(head '(9))", "9"),
        ("(head '())", "<nothing>")
    ] as [ValueCase])
    func head(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("tail", arguments: [
        ("(tail '(1 2 3))", "(2 3)"),
        ("(tail '(1))", "()"),
        ("(tail '())", "()")
    ] as [ValueCase])
    func tail(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("last", arguments: [
        ("(last '(1 2 3))", "3"),
        ("(last '(9))", "9"),
        ("(last '())", "<nothing>")
    ] as [ValueCase])
    func last(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("take", arguments: [
        ("(take 2 '(1 2 3))", "(1 2)"),
        ("(take 0 '(1 2 3))", "()"),
        ("(take 5 '(1 2))", "(1 2)")
    ] as [ValueCase])
    func take(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("drop", arguments: [
        ("(drop 1 '(1 2 3))", "(2 3)"),
        ("(drop 0 '(1 2 3))", "(1 2 3)"),
        ("(drop 5 '(1 2))", "()")
    ] as [ValueCase])
    func drop(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("take-last", arguments: [
        ("(take-last 2 '(1 2 3))", "(2 3)"),
        ("(take-last 0 '(1 2 3))", "()"),
        ("(take-last 5 '(1 2))", "(1 2)"),
        ("(take-last 1 '())", "()")
    ] as [ValueCase])
    func takeLast(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("drop-last", arguments: [
        ("(drop-last 1 '(1 2 3))", "(1 2)"),
        ("(drop-last 0 '(1 2 3))", "(1 2 3)"),
        ("(drop-last 5 '(1 2))", "()"),
        ("(drop-last 1 '())", "()")
    ] as [ValueCase])
    func dropLast(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("take-last and drop-last split a list between them")
    func takeLastDropLastSplit() {
        expectValue("(append (drop-last 2 '(1 2 3 4)) (take-last 2 '(1 2 3 4)))", "(1 2 3 4)")
    }

    @Test("range extracts from the start up to the finish, excluding it", arguments: [
        ("(range 1 3 '(a b c d e))", "(b c)"),
        ("(range 0 5 '(a b c d e))", "(a b c d e)"),
        ("(range 1 99 '(a b c d e))", "(b c d e)"),
        ("(range 2 2 '(a b c d e))", "()"),
        ("(range 3 1 '(a b c d e))", "()"),
        ("(range 5 7 '(a b c d e))", "()"),
        ("(range 0 1 '())", "()")
    ] as [ValueCase])
    func range(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("range-len extracts a length from the start", arguments: [
        ("(range-len 1 2 '(a b c d e))", "(b c)"),
        ("(range-len 0 5 '(a b c d e))", "(a b c d e)"),
        ("(range-len 3 99 '(a b c d e))", "(d e)"),
        ("(range-len 2 0 '(a b c d e))", "()"),
        ("(range-len 5 2 '(a b c d e))", "()"),
        ("(range-len 1 9223372036854775807 '(a b c))", "(b c)"),
        ("(range-len 0 1 '())", "()")
    ] as [ValueCase])
    func rangeLen(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("range and range-len agree with take and drop")
    func rangeAgreesWithTakeDrop() {
        let xs = "'(a b c d e f)"
        expectValue("(eq (range 2 5 \(xs)) (take 3 (drop 2 \(xs))))", "true")
        expectValue("(eq (range-len 2 3 \(xs)) (take 3 (drop 2 \(xs))))", "true")
    }

    @Test("length", arguments: [
        ("(length '(1 2 3))", "3"),
        ("(length '())", "0"),
        ("(length '(1))", "1")
    ] as [ValueCase])
    func length(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("empty?", arguments: [
        ("(empty? '())", "true"),
        ("(empty? '(1))", "false"),
        ("(empty? '(1 2 3))", "false")
    ] as [ValueCase])
    func empty(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("init", arguments: [
        ("(init '(1 2 3))", "(1 2)"),
        ("(init '(1))", "()"),
        ("(init '())", "()")
    ] as [ValueCase])
    func initial(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("cons", arguments: [
        ("(cons 1 '(2 3))", "(1 2 3)"),
        ("(cons 1 '())", "(1)"),
        ("(cons '(1) '(2))", "((1) 2)")
    ] as [ValueCase])
    func cons(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("list", arguments: [
        ("(list)", "()"),
        ("(list 1 2 3)", "(1 2 3)"),
        ("(list '(1) '(2))", "((1) (2))"),
        ("(list (+ 1 1) (* 2 2))", "(2 4)")
    ] as [ValueCase])
    func list(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("append", arguments: [
        ("(append '(1) '(2) '(3))", "(1 2 3)"),
        ("(append '(1 2))", "(1 2)"),
        ("(append '() '())", "()"),
        ("(append '(1 2) '())", "(1 2)")
    ] as [ValueCase])
    func append(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("reverse", arguments: [
        ("(reverse '(1 2 3))", "(3 2 1)"),
        ("(reverse '(1))", "(1)"),
        ("(reverse '())", "()")
    ] as [ValueCase])
    func reverse(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("nth", arguments: [
        ("(nth 0 '(1 2 3))", "1"),
        ("(nth 2 '(1 2 3))", "3")
    ] as [ValueCase])
    func nth(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("contains", arguments: [
        ("(contains? 2 '(1 2 3))", "true"),
        ("(contains? 9 '(1 2 3))", "false"),
        ("(contains? 2 '())", "false"),
        ("(contains? '(1) '((1) (2)))", "true")
    ] as [ValueCase])
    func contains(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("contains does not equate across types")
    func containsAcrossTypes() {
        expectValue("(contains? \"a\" '(1 2))", "false")
        expectValue("(contains? 1 '(1.0 2.0))", "false")
    }

    @Test("lists can be built by recursion")
    func recursiveConstruction() {
        expectValue(
            """
            (define (my-map f xs) (if (empty? xs) '() (cons (f (head xs)) (my-map f (tail xs)))))
            (my-map (lambda (x) (* x x)) '(1 2 3 4))
            """,
            "(1 4 9 16)")
    }

    @Test("zip pairs elements and stops at the shorter list", arguments: [
        ("(zip '(1 2 3) '(a b c))", "((1 a) (2 b) (3 c))"),
        ("(zip '(1 2 3) '(a b))", "((1 a) (2 b))"),
        ("(zip '(1) '(a b c))", "((1 a))"),
        ("(zip '() '(1 2))", "()"),
        ("(zip '(1 2) '())", "()"),
        ("(zip '() '())", "()"),
        ("(length (zip (integers 3) (integers 7)))", "3"),
        ("(zip '((1) (2)) '(\"a\" \"b\"))", "(((1) \"a\") ((2) \"b\"))")
    ] as [ValueCase])
    func zip(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("zip carries elements that are themselves nothing", arguments: [
        ("(zip (list nothing 1) (list nothing 2))", "((<nothing> <nothing>) (1 2))"),
        ("(zip (list 1 nothing 3) '(a b c))", "((1 a) (<nothing> b) (3 c))"),
        ("(zip (list nothing nothing) '(a))", "((<nothing> a))")
    ] as [ValueCase])
    func zipCarriesNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("zip-all pairs elements and pads the shorter list with nothing", arguments: [
        ("(zip-all '(1 2 3) '(a b c))", "((1 a) (2 b) (3 c))"),
        ("(zip-all '(1 2 3) '(a b))", "((1 a) (2 b) (3 <nothing>))"),
        ("(zip-all '(1) '(a b c))", "((1 a) (<nothing> b) (<nothing> c))"),
        ("(zip-all '() '(1 2))", "((<nothing> 1) (<nothing> 2))"),
        ("(zip-all '(1 2) '())", "((1 <nothing>) (2 <nothing>))"),
        ("(zip-all '() '())", "()"),
        ("(length (zip-all (integers 3) (integers 7)))", "7")
    ] as [ValueCase])
    func zipAll(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // A padding nothing is indistinguishable from an element that is nothing,
    // so zip-all must run to the end of the longer list, not stop at a nothing.
    @Test("zip-all carries elements that are themselves nothing", arguments: [
        ("(zip-all (list nothing 1) (list nothing 2))", "((<nothing> <nothing>) (1 2))"),
        ("(zip-all (list 1 nothing 3) '(a b c))", "((1 a) (<nothing> b) (3 c))"),
        ("(zip-all (list 1 nothing) '(a))", "((1 a) (<nothing> <nothing>))"),
        ("(zip-all (list nothing) '())", "((<nothing> <nothing>))")
    ] as [ValueCase])
    func zipAllCarriesNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("zip and zip-all agree on lists of equal length")
    func zipAndZipAllAgree() {
        expectValue("(eq (zip '(1 2 3) '(a b c)) (zip-all '(1 2 3) '(a b c)))", "true")
        expectValue("(eq (zip '() '()) (zip-all '() '()))", "true")
    }

    @Test("zip makes an alist, whatever the lengths")
    func zipMakesAnAlist() {
        expectValue("(get 'b (zip '(a b) '(1 2)))", "2")
        expectValue("(get 'b (make-hashmap (zip '(a b) '(1 2))))", "2")
        expectValue("(length (make-hashmap (zip '(a b c) '(1 2))))", "2")
        expectValue("(get 'c (zip '(a b c) '(1 2)))", "<nothing>")
    }

    // An alist entry may not hold nothing, so the padding makes a zip-all of
    // unequal lengths unusable as one.
    @Test("zip-all over lists of unequal length is not an alist")
    func zipAllOfUnequalLengthsIsNotAnAlist() {
        expectValue("(get 'b (make-hashmap (zip-all '(a b) '(1 2))))", "2")
        expectFailure("(make-hashmap (zip-all '(a b c) '(1 2)))", reason: .malformedAlist(2))
        expectFailure("(get 'c (zip-all '(a b c) '(1 2)))", reason: .malformedAlist(2))
    }

    @Test("flatten opens every nested list", arguments: [
        ("(flatten '(1 2 3))", "(1 2 3)"),
        ("(flatten '(1 (2 3)))", "(1 2 3)"),
        ("(flatten '((1 2) (3) ()))", "(1 2 3)"),
        ("(flatten '((a b) c ((d) e) f))", "(a b c d e f)"),
        ("(flatten '((((1))) 2))", "(1 2)"),
        ("(flatten '(() (()) 1))", "(1)"),
        ("(flatten '())", "()"),
        ("(flatten '(()))", "()"),
        ("(flatten '(\"ab\" (\"c\")))", "(\"ab\" \"c\")")
    ] as [ValueCase])
    func flatten(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("flatten leaves sets and hashmaps whole")
    func flattenOpensOnlyLists() {
        expectValue("(length (flatten (list (set 1 2) (make-hashmap) '(1))))", "3")
        expectValue("(set? (head (flatten (list (list (set 1 2))))))", "true")
    }

    @Test("flatten reaches the bottom of a deeply nested list")
    func flattenDeep() {
        let nest = "(define (nest n x) (if (== n 0) x (nest (- n 1) (list x))))"
        expectValue(nest + " (flatten (nest 500 '(1 2)))", "(1 2)")
        expectValue(nest + " (flatten (list 0 (nest 500 1) 2))", "(0 1 2)")
    }

    @Test("integers counts up from zero, excluding the limit", arguments: [
        ("(integers 5)", "(0 1 2 3 4)"),
        ("(integers 1)", "(0)"),
        ("(integers 0)", "()"),
        ("(integers -3)", "()"),
        ("(length (integers 1000))", "1000")
    ] as [ValueCase])
    func integers(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("integers-between counts up from the start, excluding the finish", arguments: [
        ("(integers-between 2 5)", "(2 3 4)"),
        ("(integers-between -2 1)", "(-2 -1 0)"),
        ("(integers-between 0 1)", "(0)"),
        ("(integers-between 3 3)", "()"),
        ("(integers-between 5 2)", "()")
    ] as [ValueCase])
    func integersBetween(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("list errors", arguments: [
        ("(head 5)", .unexpectedType(.integer, [.string, .list])),
        ("(tail 5)", .unexpectedType(.integer, [.string, .list])),
        ("(last 5)", .unexpectedType(.integer, [.string, .list])),
        ("(empty? 5)", .unexpectedType(.integer, [.hashmap, .string, .list, .set])),
        ("(head '(1) '(2))", .unexpectedArity(2, .exactly(1))),
        ("(take -1 '(1 2))", .cannotBeNegative),
        ("(drop -1 '(1 2))", .cannotBeNegative),
        ("(take-last -1 '(1 2))", .cannotBeNegative),
        ("(drop-last -1 '(1 2))", .cannotBeNegative),
        ("(take-last \"x\" '(1))", .unexpectedType(.string, [.integer])),
        ("(range -1 2 '(1 2))", .cannotBeNegative),
        ("(range 0 -1 '(1 2))", .cannotBeNegative),
        ("(range \"x\" 1 '(1))", .unexpectedType(.string, [.integer])),
        ("(range 0 1 5)", .unexpectedType(.integer, [.list, .string])),
        ("(range 0 1)", .unexpectedArity(2, .exactly(3))),
        ("(range-len -1 2 '(1 2))", .cannotBeNegative),
        ("(range-len 0 -1 '(1 2))", .cannotBeNegative),
        ("(range-len 0 \"x\" '(1))", .unexpectedType(.string, [.integer])),
        ("(range-len 0 1 5)", .unexpectedType(.integer, [.list, .string])),
        ("(range-len 0 1)", .unexpectedArity(2, .exactly(3))),
        ("(zip '(1) 5)", .unexpectedType(.integer, [.list])),
        ("(zip 5 '(1))", .unexpectedType(.integer, [.list])),
        ("(zip '(1))", .unexpectedArity(1, .exactly(2))),
        ("(zip '(1) '(2) '(3))", .unexpectedArity(3, .exactly(2))),
        ("(zip-all '(1) 5)", .unexpectedType(.integer, [.list])),
        ("(zip-all 5 '(1))", .unexpectedType(.integer, [.list])),
        ("(zip-all '(1))", .unexpectedArity(1, .exactly(2))),
        ("(zip-all '(1) '(2) '(3))", .unexpectedArity(3, .exactly(2))),
        ("(flatten 5)", .unexpectedType(.integer, [.list, .set])),
        ("(flatten (make-hashmap))", .unexpectedType(.hashmap, [.list, .set])),
        ("(flatten)", .unexpectedArity(0, .exactly(1))),
        ("(flatten '(1) '(2))", .unexpectedArity(2, .exactly(1))),
        ("(integers 1.5)", .unexpectedType(.double, [.integer])),
        ("(integers)", .unexpectedArity(0, .exactly(1))),
        ("(integers 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(integers-between 1 2.0)", .unexpectedType(.double, [.integer])),
        ("(integers-between 1)", .unexpectedArity(1, .exactly(2))),
        ("(take \"x\" '(1))", .unexpectedType(.string, [.integer])),
        ("(take 1 5)", .unexpectedType(.integer, [.string, .list])),
        ("(init 5)", .unexpectedType(.integer, [.string, .list])),
        ("(reverse 5)", .unexpectedType(.integer, [.string, .list])),
        ("(cons 1 2)", .unexpectedType(.integer, [.list])),
        ("(cons 1)", .unexpectedArity(1, .exactly(2))),
        ("(append 5)", .unexpectedType(.integer, [.string, .list])),
        ("(append)", .unexpectedArity(0, .atLeast(1))),
        ("(nth 0 5)", .unexpectedType(.integer, [.string, .list])),
        ("(nth \"a\" '(1))", .unexpectedType(.string, [.integer])),
        ("(nth 5 '(1 2))", .subscriptOutOfBounds(5, 2)),
        ("(nth -1 '(1 2))", .subscriptOutOfBounds(-1, 2)),
        ("(nth 0 '())", .subscriptOutOfBounds(0, 0)),
        ("(contains? 1 5)", .unexpectedType(.integer, [.string, .list, .set])),
        ("(contains? 1)", .unexpectedArity(1, .exactly(2)))
    ] as [FailureCase])
    func listErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
