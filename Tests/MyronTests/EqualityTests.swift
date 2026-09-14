import Testing
@testable import Myron

// MARK: - Equality

@Suite("Equality")

struct EqualityTests {

    private static func proc() -> MyronValue {
        return .primitive { _, _ in .nothing }
    }

    private static func nest(_ depth: Int, around leaf: MyronValue) -> MyronValue {
        var value = leaf
        for _ in 0..<depth { value = .list([value]) }
        return value
    }

    private static func hashmap(_ pairs: [(MyronKey, MyronValue)]) -> MyronValue {
        var map = MyronHashmap()
        for (key, value) in pairs { map = map.put(key: key, value: value) }
        return .hashmap(map)
    }

    // MARK: isEqual, Atoms

    @Test("an atom equals itself")
    func atomsReflexive() {
        let atoms: [MyronValue] = [
            .boolean(true), .boolean(false), .integer(0), .integer(-7),
            .double(1.5), .double(0.0), .string(""), .string("a"),
            .symbol("a"), .nothing
        ]

        for atom in atoms {
            #expect(atom.isEqual(atom), "\(atom) should equal itself")
        }
    }

    @Test("atoms of the same kind compare by payload")
    func atomsByPayload() {
        #expect(MyronValue.integer(1).isEqual(.integer(1)))
        #expect(!MyronValue.integer(1).isEqual(.integer(2)))
        #expect(MyronValue.double(1.5).isEqual(.double(1.5)))
        #expect(!MyronValue.double(1.5).isEqual(.double(2.5)))
        #expect(MyronValue.boolean(true).isEqual(.boolean(true)))
        #expect(!MyronValue.boolean(true).isEqual(.boolean(false)))
        #expect(MyronValue.string("a").isEqual(.string("a")))
        #expect(!MyronValue.string("a").isEqual(.string("b")))
        #expect(MyronValue.symbol("a").isEqual(.symbol("a")))
        #expect(!MyronValue.symbol("a").isEqual(.symbol("b")))
    }

    @Test("atoms of different kinds are never equal")
    func atomsAcrossKinds() {
        #expect(!MyronValue.integer(1).isEqual(.double(1.0)))
        #expect(!MyronValue.integer(1).isEqual(.boolean(true)))
        #expect(!MyronValue.integer(1).isEqual(.string("1")))
        #expect(!MyronValue.string("a").isEqual(.symbol("a")))
        #expect(!MyronValue.nothing.isEqual(.integer(0)))
        #expect(!MyronValue.nothing.isEqual(.list([])))
    }

    @Test("nothing equals nothing")
    func nothingEqualsNothing() {
        #expect(MyronValue.nothing.isEqual(.nothing))
    }

    @Test("a nan is not equal to itself")
    func nanIsNotReflexive() {
        let nan = MyronValue.double(.nan)
        #expect(!nan.isEqual(nan))
        #expect(!MyronValue.list([nan]).isEqual(.list([nan])))
    }

    // MARK: isEqual, Lists

    @Test("lists compare element by element")
    func listElements() {
        #expect(MyronValue.list([]).isEqual(.list([])))
        #expect(MyronValue.list([.integer(1)]).isEqual(.list([.integer(1)])))
        #expect(!MyronValue.list([.integer(1)]).isEqual(.list([.integer(2)])))
        #expect(!MyronValue.list([]).isEqual(.list([.integer(1)])))
        #expect(!MyronValue.list([.integer(1)]).isEqual(.list([.integer(1), .integer(2)])))
    }

    @Test("a mismatch in a late element is still found")
    func listLateMismatch() {
        let f = MyronValue.list([.integer(1), .integer(2), .integer(3), .integer(4)])
        let s = MyronValue.list([.integer(1), .integer(2), .integer(3), .integer(5)])
        #expect(!f.isEqual(s))
    }

    @Test("nesting shape is significant, not just the flattened elements")
    func listShape() {
        // Both flatten to the elements 1, 2 but have different structure.
        let f = MyronValue.list([.list([.integer(1)]), .integer(2)])   // ((1) 2)
        let s = MyronValue.list([.list([.integer(1), .integer(2)])])   // ((1 2))
        #expect(!f.isEqual(s))
        #expect(!s.isEqual(f))
        #expect(f.isEqual(f))
        #expect(s.isEqual(s))
    }

    @Test("an empty list is distinct from a list holding an empty list")
    func emptyNesting() {
        #expect(!MyronValue.list([]).isEqual(.list([.list([])])))
        #expect(MyronValue.list([.list([])]).isEqual(.list([.list([])])))
    }

    // MARK: isEqual, Hashmaps

    @Test("hashmaps ignore key order")
    func hashmapKeyOrder() {
        let f = Self.hashmap([("a", .integer(1)), ("b", .integer(2))])
        let s = Self.hashmap([("b", .integer(2)), ("a", .integer(1))])
        #expect(f.isEqual(s))
        #expect(s.isEqual(f))
    }

    @Test("hashmaps differing in size are unequal")
    func hashmapSize() {
        let f = Self.hashmap([("a", .integer(1))])
        let s = Self.hashmap([("a", .integer(1)), ("b", .integer(2))])
        #expect(!f.isEqual(s))
        #expect(!s.isEqual(f))
    }

    @Test("hashmaps of equal size with different keys are unequal")
    func hashmapDisjointKeys() {
        let f = Self.hashmap([("a", .integer(1))])
        let s = Self.hashmap([("b", .integer(1))])
        #expect(!f.isEqual(s))
        #expect(!s.isEqual(f))
    }

    @Test("hashmaps sharing keys but not values are unequal")
    func hashmapValues() {
        let f = Self.hashmap([("a", .integer(1)), ("b", .integer(2))])
        let s = Self.hashmap([("a", .integer(1)), ("b", .integer(3))])
        #expect(!f.isEqual(s))
    }

    @Test("keys of different kinds do not collide")
    func hashmapKeyKinds() {
        let f = Self.hashmap([(.integer(1), .string("x"))])
        let s = Self.hashmap([(.string("1"), .string("x"))])
        #expect(!f.isEqual(s))
    }

    @Test("an empty hashmap equals an empty hashmap")
    func hashmapEmpty() {
        #expect(Self.hashmap([]).isEqual(Self.hashmap([])))
    }

    // MARK: isEqual, Mixed Nesting

    @Test("a hashmap nested in a list is compared structurally")
    func hashmapInList() {
        let f = MyronValue.list([Self.hashmap([("k", .integer(1))]), .integer(9)])
        let s = MyronValue.list([Self.hashmap([("k", .integer(1))]), .integer(9)])
        let t = MyronValue.list([Self.hashmap([("k", .integer(2))]), .integer(9)])
        #expect(f.isEqual(s))
        #expect(!f.isEqual(t))
    }

    @Test("a hashmap valued by a hashmap is compared structurally")
    func hashmapInHashmap() {
        let inner = Self.hashmap([("x", .integer(1))])
        let other = Self.hashmap([("x", .integer(2))])
        #expect(Self.hashmap([("k", inner)]).isEqual(Self.hashmap([("k", inner)])))
        #expect(!Self.hashmap([("k", inner)]).isEqual(Self.hashmap([("k", other)])))
    }

    @Test("a list valued by a hashmap key is compared structurally")
    func listInHashmap() {
        let f = Self.hashmap([("k", .list([.integer(1), .list([.integer(2)])]))])
        let s = Self.hashmap([("k", .list([.integer(1), .list([.integer(2)])]))])
        let t = Self.hashmap([("k", .list([.integer(1), .list([.integer(3)])]))])
        #expect(f.isEqual(s))
        #expect(!f.isEqual(t))
    }

    // MARK: isEqual, Depth

    // Depth is bounded here by the recursive teardown of a nested value on
    // release, not by `isEqual`, which walks an explicit worklist. A deeper
    // structure overflows the stack when it leaves scope, whatever we do here.
    @Test("deep nesting does not overflow the stack")
    func deepNesting() {
        let f = Self.nest(750, around: .integer(1))
        let s = Self.nest(750, around: .integer(1))
        let t = Self.nest(750, around: .integer(2))
        #expect(f.isEqual(s))
        #expect(!f.isEqual(t))
    }

    // MARK: isEqual, Inequatable Values

    @Test("inequatable values are reported unequal rather than trapping")
    func inequatableValuesAreUnequal() {
        #expect(!Self.proc().isEqual(Self.proc()))
        #expect(!MyronValue.list([Self.proc()]).isEqual(.list([Self.proc()])))
        #expect(!MyronValue.define("a").isEqual(.define("a")))
    }

    // MARK: isEquatable

    @Test("atoms are equatable")
    func equatableAtoms() {
        let atoms: [MyronValue] = [
            .boolean(true), .integer(1), .double(1.5), .string("a"),
            .symbol("a"), .nothing
        ]

        for atom in atoms {
            #expect(atom.isEquatable, "\(atom) should be equatable")
        }
    }

    @Test("a nan is structurally equatable even though it equals nothing")
    func equatableNan() {
        // `isEquatable` asks whether `isEqual` can answer, not what it answers.
        #expect(MyronValue.double(.nan).isEquatable)
    }

    @Test("empty containers are equatable")
    func equatableEmptyContainers() {
        #expect(MyronValue.list([]).isEquatable)
        #expect(Self.hashmap([]).isEquatable)
    }

    @Test("containers of equatable values are equatable")
    func equatableContainers() {
        #expect(MyronValue.list([.integer(1), .string("a")]).isEquatable)
        #expect(Self.hashmap([("k", .list([.integer(1)]))]).isEquatable)
    }

    @Test("a procedure is not equatable")
    func inequatableProcedure() {
        #expect(!Self.proc().isEquatable)
        #expect(!MyronValue.define("a").isEquatable)
    }

    @Test("a procedure anywhere inside makes the whole value inequatable")
    func inequatableNested() {
        #expect(!MyronValue.list([.integer(1), Self.proc()]).isEquatable)
        #expect(!MyronValue.list([.list([Self.proc()])]).isEquatable)
        #expect(!Self.hashmap([("k", Self.proc())]).isEquatable)
        #expect(!Self.hashmap([("k", .list([Self.proc()]))]).isEquatable)
        #expect(!MyronValue.list([Self.hashmap([("k", Self.proc())])]).isEquatable)
    }

    @Test("a deeply buried procedure is still found")
    func inequatableDeep() {
        #expect(!Self.nest(750, around: Self.proc()).isEquatable)
    }

    // MARK: equatable?

    @Test("equatable?", arguments: [
        ("(equatable? 1)", "true"),
        ("(equatable? 1.0)", "true"),
        ("(equatable? (sqrt -1.0))", "true"),
        ("(equatable? \"a\")", "true"),
        ("(equatable? 'a)", "true"),
        ("(equatable? true)", "true"),
        ("(equatable? nothing)", "true"),
        ("(equatable? '())", "true"),
        ("(equatable? '(1 2))", "true"),
        ("(equatable? '(1 (2 (3))))", "true"),
        ("(equatable? (make-hashmap))", "true"),
        ("(equatable? (make-hashmap '((\"a\" 1))))", "true"),
        ("(equatable? (lambda (x) x))", "false"),
        ("(equatable? eq)", "false"),
        ("(equatable? map)", "false"),
        ("(equatable? (list 1 (lambda (x) x)))", "false"),
        ("(equatable? (list (list (lambda (x) x))))", "false"),
        ("(equatable? (put \"a\" (lambda (x) x) (make-hashmap)))", "false")
    ] as [ValueCase])
    func isEquatablePredicate(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("equatable? wants exactly one argument", arguments: [
        "(equatable?)",
        "(equatable? 1 2)"
    ])
    func isEquatableArity(_ source: String) {
        expectArityFailure(source)
    }

    // MARK: eq

    @Test("eq agrees with isEqual on structure", arguments: [
        ("(eq '((1) 2) '((1 2)))", "false"),
        ("(eq '((1) 2) '((1) 2))", "true"),
        ("(eq '(1 (2 (3))) '(1 (2 (3))))", "true"),
        ("(eq '(1 (2 (3))) '(1 (2 (4))))", "false"),
        ("(eq '() '())", "true"),
        ("(eq '() '(()))", "false"),
        ("(eq (sqrt -1.0) (sqrt -1.0))", "false"),
        (
            "(eq (make-hashmap '((\"a\" 1) (\"b\" 2))) "
            + "(make-hashmap '((\"b\" 2) (\"a\" 1))))",
            "true"
        ),
        ("(eq (make-hashmap '((\"a\" 1))) (make-hashmap '((\"b\" 1))))", "false"),
        ("(eq (make-hashmap '((\"a\" 1))) (make-hashmap '((\"a\" 2))))", "false")
    ] as [ValueCase])
    func eqStructure(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // `eq` screens both arguments before comparing, so an inequatable value is
    // an error even where a kind mismatch would otherwise have settled it.
    @Test("eq rejects an inequatable argument", arguments: [
        ("(eq (lambda (x) x) (lambda (x) x))", .inequatableTypes),
        ("(eq 1 (lambda (x) x))", .inequatableTypes),
        ("(eq (lambda (x) x) 1)", .inequatableTypes),
        ("(eq '(1) (list 1 (lambda (x) x)))", .inequatableTypes),
        ("(eq 1 (list (lambda (x) x)))", .inequatableTypes),
        ("(eq (make-hashmap) (put \"a\" (lambda (x) x) (make-hashmap)))", .inequatableTypes),
        ("(neq 1 (lambda (x) x))", .inequatableTypes)
    ] as [FailureCase])
    func eqRejectsInequatable(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("contains propagates the inequatable error", arguments: [
        ("(contains 5 (list 1 (lambda (x) x)))", .inequatableTypes)
    ] as [FailureCase])
    func containsPropagates(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
