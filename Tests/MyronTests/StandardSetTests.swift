import Testing
@testable import Myron

// MARK: - Sets

@Suite("Standard Set")

struct StandardSetTests {

    private static let nan = "(sqrt -1.0)"

    // MARK: Construction

    @Test("set", arguments: [
        ("(set)", "{}"),
        ("(set 1)", "{1}"),
        ("(empty? (set))", "true"),
        ("(length (set))", "0"),
        ("(length (set 1 2 3))", "3"),
        ("(empty? (set 1))", "false"),
        ("(length (set 1 \"a\" 'b true))", "4")
    ] as [ValueCase])
    func setConstruction(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a set holds each member once", arguments: [
        ("(length (set 1 1 2))", "2"),
        ("(length (set 1 1 1))", "1"),
        ("(length (set \"a\" \"a\"))", "1"),
        ("(length (set '(1 2) '(1 2)))", "1"),
        ("(length (set (set 1) (set 1)))", "1")
    ] as [ValueCase])
    func membersAreDistinct(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("members are distinguished by type", arguments: [
        ("(length (set 1 1.0))", "2"),
        ("(length (set 1 \"1\"))", "2"),
        ("(length (set 'a \"a\"))", "2"),
        ("(length (set 1 true))", "2")
    ] as [ValueCase])
    func memberTypes(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: make-set

    @Test("make-set", arguments: [
        ("(make-set)", "{}"),
        ("(make-set '())", "{}"),
        ("(make-set '(1))", "{1}"),
        ("(length (make-set '(1 2 3)))", "3"),
        ("(length (make-set '(1 1 2)))", "2"),
        ("(length (make-set (make-hashmap)))", "0"),
        ("(length (make-set (make-hashmap '((\"a\" 1) (\"b\" 2)))))", "2")
    ] as [ValueCase])
    func makeSet(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("make-set over a hashmap holds its key-value pairs")
    func makeSetFromHashmap() {
        let hashmap = "(make-hashmap '((\"a\" 1)))"
        expectValue("(contains? '(\"a\" 1) (make-set \(hashmap)))", "true")
        expectValue("(contains? '(\"a\" 2) (make-set \(hashmap)))", "false")
    }

    @Test("a list round trips through a set")
    func roundTrip() {
        expectValue("(eq (make-set (values (set 1 2 3))) (set 1 2 3))", "true")
        expectValue("(length (values (make-set '(1 2 3))))", "3")
        expectValue("(list? (values (set 1 2)))", "true")
    }

    @Test("make-set takes a list or a hashmap only", arguments: [
        ("(make-set 5)", .unexpectedType(.integer, [.list, .hashmap])),
        ("(make-set \"ab\")", .unexpectedType(.string, [.list, .hashmap])),
        ("(make-set (set 1))", .unexpectedType(.set, [.list, .hashmap]))
    ] as [FailureCase])
    func makeSetKinds(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: Membership

    @Test("insert and remove", arguments: [
        ("(length (insert 1 (set)))", "1"),
        ("(length (insert 3 (set 1 2)))", "3"),
        ("(length (insert 1 (set 1 2)))", "2"),
        ("(length (remove 1 (set 1 2)))", "1"),
        ("(length (remove 9 (set 1 2)))", "2"),
        ("(length (remove 1 (set)))", "0"),
        ("(eq (insert 3 (set 1 2)) (set 1 2 3))", "true"),
        ("(eq (remove 3 (set 1 2 3)) (set 1 2))", "true")
    ] as [ValueCase])
    func insertAndRemove(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("insert and remove leave the original set alone")
    func membershipIsPersistent() {
        expectValue(
            "(define s (set 1 2)) (define t (insert 3 s)) (list (length s) (length t))",
            "(2 3)")
        expectValue(
            "(define s (set 1 2)) (define t (remove 1 s)) (list (length s) (length t))",
            "(2 1)")
    }

    @Test("contains?", arguments: [
        ("(contains? 1 (set 1 2))", "true"),
        ("(contains? 9 (set 1 2))", "false"),
        ("(contains? 1 (set))", "false"),
        ("(contains? '(1) (set '(1) '(2)))", "true"),
        ("(contains? 1 (set 1.0))", "false"),
        ("(contains? \"a\" (set 'a))", "false")
    ] as [ValueCase])
    func contains(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Unstorable Members

    @Test("a member that cannot be found is never stored", arguments: [
        ("(length (set \(nan)))", "0"),
        ("(length (set \(nan) \(nan)))", "0"),
        ("(length (set \(nan) 1))", "1"),
        ("(values (set \(nan) 1))", "(1)"),
        ("(length (insert \(nan) (set)))", "0"),
        ("(length (make-set (list \(nan))))", "0"),
        ("(length (make-set (list \(nan) 1)))", "1"),
        ("(eq (set \(nan) 1) (set 1))", "true")
    ] as [ValueCase])
    func unstorableMembers(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("an unstorable member is dropped, not stored as nothing")
    func unstorableIsNotNothing() {
        expectValue("(contains? (head '()) (set \(Self.nan)))", "false")
        expectValue("(length (set \(Self.nan) (head '())))", "1")
    }

    // MARK: Set Operations

    @Test("union", arguments: [
        ("(eq (union (set 1 2) (set 2 3)) (set 1 2 3))", "true"),
        ("(eq (union (set 1) (set)) (set 1))", "true"),
        ("(eq (union (set) (set)) (set))", "true"),
        ("(eq (union (set 1) (set 2) (set 3)) (set 1 2 3))", "true"),
        ("(eq (union (set 1 2)) (set 1 2))", "true"),
        ("(length (union (set 1 2) (set 1 2)))", "2")
    ] as [ValueCase])
    func union(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("intersection", arguments: [
        ("(eq (intersection (set 1 2) (set 2 3)) (set 2))", "true"),
        ("(eq (intersection (set 1) (set 2)) (set))", "true"),
        ("(eq (intersection (set 1) (set)) (set))", "true"),
        ("(eq (intersection (set 1 2 3) (set 1 2) (set 2)) (set 2))", "true"),
        ("(eq (intersection (set 1 2)) (set 1 2))", "true")
    ] as [ValueCase])
    func intersection(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("difference removes the members of the later sets", arguments: [
        ("(eq (difference (set 1 2 3) (set 2)) (set 1 3))", "true"),
        ("(eq (difference (set 1 2 3) (set 2) (set 3)) (set 1))", "true"),
        ("(eq (difference (set 1) (set 1)) (set))", "true"),
        ("(eq (difference (set 1) (set 9)) (set 1))", "true"),
        ("(eq (difference (set) (set 1)) (set))", "true")
    ] as [ValueCase])
    func difference(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("difference is not symmetric difference")
    func differenceIsRelativeComplement() {
        expectValue("(eq (difference (set 1 2) (set 2 3)) (set 1))", "true")
        expectValue("(eq (symmetric-difference (set 1 2) (set 2 3)) (set 1 3))", "true")
    }

    @Test("symmetric-difference", arguments: [
        ("(eq (symmetric-difference (set 1 2) (set 2 3)) (set 1 3))", "true"),
        ("(eq (symmetric-difference (set 1) (set 1)) (set))", "true"),
        ("(eq (symmetric-difference (set 1) (set)) (set 1))", "true"),
        ("(eq (symmetric-difference (set) (set)) (set))", "true")
    ] as [ValueCase])
    func symmetricDifference(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Relations

    @Test("subset and superset", arguments: [
        ("(is-subset? (set 1) (set 1 2))", "true"),
        ("(is-subset? (set 1 2) (set 1 2))", "true"),
        ("(is-subset? (set) (set 1))", "true"),
        ("(is-subset? (set 1 2) (set 1))", "false"),
        ("(is-strict-subset? (set 1) (set 1 2))", "true"),
        ("(is-strict-subset? (set 1 2) (set 1 2))", "false"),
        ("(is-superset? (set 1 2) (set 1))", "true"),
        ("(is-superset? (set 1 2) (set 1 2))", "true"),
        ("(is-superset? (set 1) (set 1 2))", "false"),
        ("(is-strict-superset? (set 1 2) (set 1))", "true"),
        ("(is-strict-superset? (set 1 2) (set 1 2))", "false")
    ] as [ValueCase])
    func subsetAndSuperset(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("is-disjoint?", arguments: [
        ("(is-disjoint? (set 1) (set 2))", "true"),
        ("(is-disjoint? (set 1) (set 1))", "false"),
        ("(is-disjoint? (set) (set 1))", "true"),
        ("(is-disjoint? (set) (set))", "true"),
        ("(is-disjoint? (set 1 2) (set 2 3))", "false")
    ] as [ValueCase])
    func isDisjoint(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Powerset

    @Test("powerset", arguments: [
        ("(eq (powerset (set 1)) (set (set) (set 1)))", "true"),
        ("(eq (powerset (set 1 2)) (set (set) (set 1) (set 2) (set 1 2)))", "true"),
        ("(length (powerset (set 1 2 3)))", "8"),
        ("(length (powerset (set 1 2 3 4 5)))", "32"),
        ("(length (powerset (set 1 \"a\" 'b)))", "8")
    ] as [ValueCase])
    func powerset(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the powerset of the empty set holds the empty set", arguments: [
        ("(length (powerset (set)))", "1"),
        ("(eq (powerset (set)) (set (set)))", "true"),
        ("(contains? (set) (powerset (set)))", "true")
    ] as [ValueCase])
    func powersetOfEmpty(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a powerset holds every subset and nothing else", arguments: [
        ("(all set? (powerset (set 1 2 3)))", "true"),
        ("(all (lambda (s) (is-subset? s (set 1 2 3))) (powerset (set 1 2 3)))", "true"),
        ("(contains? (set) (powerset (set 1 2 3)))", "true"),
        ("(contains? (set 1 2 3) (powerset (set 1 2 3)))", "true"),
        ("(contains? (set 1 3) (powerset (set 1 2 3)))", "true"),
        ("(contains? (set 4) (powerset (set 1 2 3)))", "false"),
        ("(contains? 1 (powerset (set 1 2 3)))", "false")
    ] as [ValueCase])
    func powersetMembers(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Cartesian Product

    @Test("cartesian-product", arguments: [
        ("(eq (cartesian-product (set 1 2) (set 'a 'b)) (set '(1 a) '(1 b) '(2 a) '(2 b)))", "true"),
        ("(values (cartesian-product (set 1) (set 2)))", "((1 2))"),
        ("(length (cartesian-product (set 1 2) (set 3 4 5)))", "6"),
        ("(length (cartesian-product (set 1 2) (set 1 2)))", "4"),
        ("(contains? '(1 1) (cartesian-product (set 1 2) (set 1 2)))", "true")
    ] as [ValueCase])
    func cartesianProduct(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a cartesian product keeps the order of its sets", arguments: [
        ("(contains? '(1 a) (cartesian-product (set 1) (set 'a)))", "true"),
        ("(contains? '(a 1) (cartesian-product (set 1) (set 'a)))", "false"),
        ("(eq (cartesian-product (set 1 2) (set 3)) (cartesian-product (set 3) (set 1 2)))", "false")
    ] as [ValueCase])
    func cartesianProductIsOrdered(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("an empty set empties the cartesian product", arguments: [
        ("(eq (cartesian-product (set) (set 1 2)) (set))", "true"),
        ("(eq (cartesian-product (set 1 2) (set)) (set))", "true"),
        ("(eq (cartesian-product (set 1) (set) (set 2)) (set))", "true")
    ] as [ValueCase])
    func cartesianProductOfEmpty(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("more than two sets make flat tuples, not nested pairs", arguments: [
        ("(eq (cartesian-product (set 1) (set 2) (set 3)) (set '(1 2 3)))", "true"),
        ("(length (cartesian-product (set 1 2) (set 3 4) (set 5 6)))", "8"),
        ("(all (lambda (t) (eq (length t) 3)) (cartesian-product (set 1 2) (set 3 4) (set 5 6)))", "true"),
        ("(length (cartesian-product (set 1 2) (set 3) (set 4 5) (set 6 7 8)))", "12")
    ] as [ValueCase])
    func cartesianProductVariadic(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Equality

    @Test("sets are compared by membership, not by order", arguments: [
        ("(eq (set 1 2 3) (set 3 2 1))", "true"),
        ("(eq (set 1 2) (set 1 2 3))", "false"),
        ("(eq (set 1) (set 1.0))", "false"),
        ("(eq (set) (set))", "true"),
        ("(eq (set (set 1)) (set (set 1)))", "true"),
        ("(eq (set '(1 2)) (set '(1 2)))", "true"),
        ("(eq (set 1) '(1))", "false")
    ] as [ValueCase])
    func equality(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a reduced set equals a freshly built one")
    func equalityIgnoresLayout() {
        let reduced = """
            (remove 12 (remove 11 (remove 10 (remove 9 (remove 8 (remove 7 (remove 6
            (remove 5 (remove 4 (set 1 2 3 4 5 6 7 8 9 10 11 12))))))))))
            """
        expectValue("(eq \(reduced) (set 1 2 3))", "true")
        expectValue("(eq (set 1 2 3) \(reduced))", "true")
        expectValue("(length \(reduced))", "3")
    }

    // MARK: Sets As Keys

    @Test("a set can key a hashmap by its membership")
    func setsAsKeys() {
        let hashmap = "(put (set 1 2) 9 (make-hashmap))"
        expectValue("(get (set 2 1) \(hashmap))", "9")
        expectValue("(get (set 1) \(hashmap))", "<nothing>")
        expectValue("(has-key? (set 1 2) \(hashmap))", "true")
    }

    // MARK: Predicate

    @Test("set?", arguments: [
        ("(set? (set))", "true"),
        ("(set? (set 1))", "true"),
        ("(set? (make-set '(1)))", "true"),
        ("(set? '(1))", "false"),
        ("(set? 4.0)", "false"),
        ("(set? (make-hashmap))", "false"),
        ("(set? \"set\")", "false")
    ] as [ValueCase])
    func setPredicate(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Shared Names

    @Test("a shared name works over a set", arguments: [
        ("(length (set 1 2))", "2"),
        ("(empty? (set))", "true"),
        ("(length (values (set 1 2)))", "2"),
        ("(contains? 1 (set 1))", "true"),
        ("(length (remove 1 (set 1)))", "0")
    ] as [ValueCase])
    func sharedNames(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Higher-Order Operations

    @Test("map and filter give back the kind they were given", arguments: [
        ("(set? (map (lambda (x) x) (set 1)))", "true"),
        ("(list? (map (lambda (x) x) '(1)))", "true"),
        ("(set? (filter (lambda (x) true) (set 1)))", "true"),
        ("(list? (filter (lambda (x) true) '(1)))", "true"),
        ("(set? (map (lambda (x) x) (set)))", "true"),
        ("(list? (map (lambda (x) x) '()))", "true"),
        ("(set? (filter (lambda (x) true) (set)))", "true"),
        ("(list? (filter (lambda (x) true) '()))", "true")
    ] as [ValueCase])
    func shapeIsPreserved(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("map over a set", arguments: [
        ("(eq (map (lambda (x) (* x 2)) (set 1 2 3)) (set 2 4 6))", "true"),
        ("(map (lambda (x) x) (set))", "{}"),
        ("(map (lambda (x) (* x 2)) (set 1))", "{2}")
    ] as [ValueCase])
    func mapOverSet(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("map over a set collapses members that agree")
    func mapCollapses() {
        expectValue("(length (map (lambda (x) 0) (set 1 2 3)))", "1")
        expectValue("(eq (map (lambda (x) 0) (set 1 2 3)) (set 0))", "true")
        expectValue("(length (map (lambda (x) 0) '(1 2 3)))", "3")
    }

    @Test("map over a set drops a member it could not store")
    func mapDropsUnstorable() {
        expectValue("(length (map (lambda (x) (sqrt x)) (set -1.0 4.0)))", "1")
        expectValue("(values (map (lambda (x) (sqrt x)) (set -1.0 4.0)))", "(2.0)")
    }

    @Test("filter over a set", arguments: [
        ("(eq (filter (lambda (x) (gt x 0)) (set -1 2 -3 4)) (set 2 4))", "true"),
        ("(eq (filter (lambda (x) false) (set 1 2)) (set))", "true"),
        ("(eq (filter (lambda (x) true) (set 1 2)) (set 1 2))", "true"),
        ("(filter (lambda (x) true) (set))", "{}")
    ] as [ValueCase])
    func filterOverSet(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("reduce, all and any over a set", arguments: [
        ("(reduce + 0 (set 1 2 3))", "6"),
        ("(reduce + 0 (set))", "0"),
        ("(reduce * 1 (set 2 3 4))", "24"),
        ("(all (lambda (x) (gt x 0)) (set 1 2))", "true"),
        ("(all (lambda (x) (gt x 1)) (set 1 2))", "false"),
        ("(all (lambda (x) false) (set))", "true"),
        ("(any (lambda (x) (gt x 1)) (set 1 2))", "true"),
        ("(any (lambda (x) (gt x 5)) (set 1 2))", "false"),
        ("(any (lambda (x) true) (set))", "false")
    ] as [ValueCase])
    func probesOverSet(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Errors

    @Test("set operations take sets", arguments: [
        ("(union (set 1) '(2))", .unexpectedType(.list, [.set])),
        ("(intersection (set 1) 5)", .unexpectedType(.integer, [.set])),
        ("(difference (set 1) \"a\")", .unexpectedType(.string, [.set])),
        ("(symmetric-difference (set 1) '(2))", .unexpectedType(.list, [.set])),
        ("(is-subset? (set 1) 5)", .unexpectedType(.integer, [.set])),
        ("(is-superset? (set 1) 5)", .unexpectedType(.integer, [.set])),
        ("(is-disjoint? (set 1) 5)", .unexpectedType(.integer, [.set])),
        ("(insert 1 '(2))", .unexpectedType(.list, [.set])),
        ("(powerset '(1 2))", .unexpectedType(.list, [.set])),
        ("(powerset 5)", .unexpectedType(.integer, [.set])),
        ("(cartesian-product (set 1) '(2))", .unexpectedType(.list, [.set])),
        ("(cartesian-product 5 (set 1))", .unexpectedType(.integer, [.set])),
        ("(cartesian-product (set 1) (set 2) \"a\")", .unexpectedType(.string, [.set]))
    ] as [FailureCase])
    func unexpectedType(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("set arity errors", arguments: [
        "(insert 1)", "(insert)", "(contains? 1)",
        "(union)", "(intersection)",
        "(symmetric-difference (set 1))", "(symmetric-difference)",
        "(is-subset? (set 1))", "(is-strict-subset? (set 1))",
        "(is-superset? (set 1))", "(is-strict-superset? (set 1))",
        "(is-disjoint? (set 1))", "(make-set '(1) '(2))",
        "(powerset)", "(powerset (set 1) (set 2))",
        "(cartesian-product)", "(cartesian-product (set 1))"
    ])
    func arityErrors(_ source: String) {
        expectArityFailure(source)
    }

}
