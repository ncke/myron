import Testing
@testable import Myron

// MARK: - Records

@Suite("Standard Record")

struct StandardRecordTests {

    private static let point = "(define point (make-record-type 'point '(x y)))"
    private static let p = point + " (define p (make-record point 1 2))"
    private static let nan = "(sqrt -1.0)"

    // MARK: make-record-type

    @Test("make-record-type", arguments: [
        ("(make-record-type 'point '(x y))", "<record-type: point x y>"),
        ("(make-record-type 'unit '())", "<record-type: unit>"),
        ("(kind (make-record-type 'point '(x y)))", "\"record-type\"")
    ] as [ValueCase])
    func makeRecordType(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("make-record-type rejects a malformed definition", arguments: [
        ("(make-record-type 'point '(x x))", .duplicateField("x", "point")),
        ("(make-record-type 'if '(x))", .invalidName("if")),
        ("(make-record-type 'point '(if))", .invalidName("if")),
        ("(make-record-type \"point\" '(x))", .unexpectedType(.string, [.symbol])),
        ("(make-record-type 'point '(x \"y\"))", .unexpectedType(.string, [.symbol])),
        ("(make-record-type 'point 5)", .unexpectedType(.integer, [.list]))
    ] as [FailureCase])
    func makeRecordTypeFailures(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: make-record

    @Test("make-record", arguments: [
        (p + " p", "<record: point (x: 1 y: 2)>"),
        (p + " (kind p)", "\"record\""),
        ("(make-record (make-record-type 'unit '()))", "<record: unit ()>"),
        (point + " (make-record point nothing 2)", "<record: point (x: <nothing> y: 2)>"),
        (point + " (make-record point '(1 2) \"a\")", "<record: point (x: (1 2) y: \"a\")>"),
        (p + " (make-record point p p)",
         "<record: point (x: <record: point (x: 1 y: 2)> y: <record: point (x: 1 y: 2)>)>")
    ] as [ValueCase])
    func makeRecord(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("make-record takes a value for every field", arguments: [
        (point + " (make-record point 1)", .unexpectedArity(2, .exactly(3))),
        (point + " (make-record point 1 2 3)", .unexpectedArity(4, .exactly(3))),
        ("(make-record (make-record-type 'unit '()) 1)", .unexpectedArity(2, .exactly(1))),
        ("(make-record)", .unexpectedArity(0, .atLeast(1))),
        ("(make-record 5 1 2)", .unexpectedType(.integer, [.recordType]))
    ] as [FailureCase])
    func makeRecordFailures(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: get & put

    @Test("get", arguments: [
        (p + " (get 'x p)", "1"),
        (p + " (get 'y p)", "2"),
        (point + " (get 'x (make-record point nothing 2))", "<nothing>")
    ] as [ValueCase])
    func get(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("put", arguments: [
        (p + " (put 'x 10 p)", "<record: point (x: 10 y: 2)>"),
        (p + " (get 'x (put 'x 10 p))", "10"),
        (p + " (put 'x nothing p)", "<record: point (x: <nothing> y: 2)>"),
        (p + " (get 'x (put 'x nothing p))", "<nothing>"),
        (p + " (record-isa? point (put 'x 10 p))", "true")
    ] as [ValueCase])
    func put(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("put leaves the original record unchanged")
    func putIsPersistent() {
        expectValue(Self.p + " (put 'x 10 p) p", "<record: point (x: 1 y: 2)>")
    }

    // Unlike a hashmap, which answers nothing for a missing key, a record has a
    // fixed shape, so naming a field it does not have is an error.
    @Test("get and put reject a field the record does not have", arguments: [
        (p + " (get 'z p)", .unexpectedField("z", "point", ["x", "y"])),
        (p + " (put 'z 1 p)", .unexpectedField("z", "point", ["x", "y"])),
        (p + " (get 'x)", .unexpectedArity(1, .exactly(2)))
    ] as [FailureCase])
    func fieldFailures(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a field is named by a symbol, not a string")
    func fieldIsASymbol() {
        expectFailure(Self.p + " (get \"x\" p)")
        expectFailure(Self.p + " (put \"x\" 1 p)")
    }

    // MARK: keys-values

    @Test("keys-values lists the fields in declaration order", arguments: [
        (p + " (keys-values p)", "((x 1) (y 2))"),
        ("(define yx (make-record-type 'yx '(y x))) (keys-values (make-record yx 1 2))",
         "((y 1) (x 2))"),
        ("(keys-values (make-record (make-record-type 'unit '())))", "()"),
        (point + " (keys-values (make-record point nothing 2))", "((x <nothing>) (y 2))")
    ] as [ValueCase])
    func keysValues(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("keys-values wants a hashmap or a record", arguments: [
        ("(keys-values 7)", .unexpectedType(.integer, [.hashmap, .record])),
        ("(keys-values '())", .unexpectedType(.list, [.hashmap, .record]))
    ] as [FailureCase])
    func keysValuesFailures(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: Introspection

    @Test("record-type-name, record-type-fields and has-field?", arguments: [
        (p + " (record-type-name point)", "point"),
        (p + " (record-type-name p)", "point"),
        (p + " (kind (record-type-name p))", "\"symbol\""),
        (p + " (record-type-fields point)", "(x y)"),
        (p + " (record-type-fields p)", "(x y)"),
        ("(record-type-fields (make-record-type 'unit '()))", "()"),
        (p + " (has-field? 'x point)", "true"),
        (p + " (has-field? 'x p)", "true"),
        (p + " (has-field? 'z point)", "false"),
        (p + " (has-field? 'z p)", "false")
    ] as [ValueCase])
    func introspection(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("introspection wants a record or a record type", arguments: [
        ("(record-type-name 'point)", .unexpectedType(.symbol, [.record, .recordType])),
        ("(record-type-fields 5)", .unexpectedType(.integer, [.record, .recordType])),
        ("(has-field? 'x 5)", .unexpectedType(.integer, [.record, .recordType])),
        (p + " (has-field? \"x\" p)", .unexpectedType(.string, [.symbol]))
    ] as [FailureCase])
    func introspectionFailures(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: record-type & record-isa?

    @Test("record-type gives the type a record was made from", arguments: [
        (p + " (record-type p)", "<record-type: point x y>"),
        (p + " (eq (record-type p) point)", "true"),
        (p + " (eq (record-type (put 'x 10 p)) point)", "true")
    ] as [ValueCase])
    func recordType(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("record-isa?", arguments: [
        (p + " (record-isa? point p)", "true"),
        (p + " (record-isa? (make-record-type 'other '(x y)) p)", "false"),
        (p + " (record-isa? point 5)", "false"),
        (p + " (record-isa? point '(1 2))", "false"),
        (p + " (record-isa? point point)", "false"),
        (p + " (record-isa? point nothing)", "false")
    ] as [ValueCase])
    func recordIsa(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("record-type and record-isa? want records and record types", arguments: [
        ("(record-type 5)", .unexpectedType(.integer, [.record])),
        (p + " (record-isa? 5 p)", .unexpectedType(.integer, [.recordType])),
        ("(record-type)", .unexpectedArity(0, .exactly(1)))
    ] as [FailureCase])
    func recordTypeFailures(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: Identity

    // A record type is identified by its name and its fields, in order, so any
    // two definitions that agree are the same type, wherever they were made.
    @Test("a record type is identified by its name and fields", arguments: [
        (point + " (eq point point)", "true"),
        (point + " (eq point (make-record-type 'point '(x y)))", "true"),
        (p + " (record-isa? (make-record-type 'point '(x y)) p)", "true"),
        (p + " (define old p) " + point + " (record-isa? point old)", "true"),
        (p + " (eq p (make-record (make-record-type 'point '(x y)) 1 2))", "true")
    ] as [ValueCase])
    func structuralTypes(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a record type differing in name or fields is another type", arguments: [
        (point + " (eq point (make-record-type 'other '(x y)))", "false"),
        (point + " (eq point (make-record-type 'point '(x z)))", "false"),
        (point + " (eq point (make-record-type 'point '(x y z)))", "false"),
        (point + " (eq point (make-record-type 'point '(x)))", "false"),
        (p + " (record-isa? (make-record-type 'point '(x y z)) p)", "false")
    ] as [ValueCase])
    func structuralDifferences(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // Fields are held by position, so a type with the same fields in another
    // order must not match, or its fields would be compared out of step.
    @Test("the order of the fields is part of the type", arguments: [
        (point + " (eq point (make-record-type 'point '(y x)))", "false"),
        (p + " (record-isa? (make-record-type 'point '(y x)) p)", "false"),
        ("(eq (make-record (make-record-type 'point '(x y)) 1 1) " +
         "(make-record (make-record-type 'point '(y x)) 1 1))", "false"),
        ("(eq (make-record (make-record-type 'point '(x y)) 1 2) " +
         "(make-record (make-record-type 'point '(y x)) 2 1))", "false")
    ] as [ValueCase])
    func fieldOrder(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("records of one type compare by their fields", arguments: [
        (p + " (eq p (make-record point 1 2))", "true"),
        (p + " (eq p (make-record point 1 3))", "false"),
        (p + " (eq p (make-record point 2 1))", "false"),
        (p + " (eq p (put 'x 1 p))", "true"),
        (p + " (eq (make-record point p 0) (make-record point (make-record point 1 2) 0))", "true"),
        (p + " (eq (make-record point p 0) (make-record point (put 'y 3 p) 0))", "false"),
        (p + " (eq p '((x 1) (y 2)))", "false")
    ] as [ValueCase])
    func equality(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a record is not comparable")
    func notComparable() {
        expectValue(Self.p + " (comparable? p)", "false")
        expectFailure(Self.p + " (lt p p)", reason: .incomparableTypes)
    }

    // MARK: Collections

    @Test("a record works as a set member and a hashmap key", arguments: [
        (p + " (length (set p (make-record point 1 2)))", "1"),
        (p + " (length (set p (make-record point 2 1)))", "2"),
        (p + " (length (set p (make-record (make-record-type 'point '(x y)) 1 2)))", "1"),
        (p + " (length (set p (make-record (make-record-type 'point '(y x)) 2 1)))", "2"),
        (p + " (length (set point (make-record-type 'point '(x y))))", "1"),
        (p + " (get (make-record point 1 2) (put p 5 (make-hashmap)))", "5"),
        (p + " (get (make-record point 2 1) (put p 5 (make-hashmap)))", "<nothing>"),
        (p + " (get (make-record (make-record-type 'point '(x y)) 1 2) (put p 5 (make-hashmap)))",
         "5"),
        (p + " (get (make-record-type 'point '(x y)) (put point 5 (make-hashmap)))", "5")
    ] as [ValueCase])
    func collections(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // A record holding a nan is not equal to itself, so like a list holding one
    // it cannot be found again and is dropped as a key.
    @Test("a record holding a nan is dropped as a key, but is fine as a value", arguments: [
        (p + " (length (keys (put (put 'x \(nan) p) 1 (make-hashmap))))", "0"),
        (p + " (length (set (put 'x \(nan) p)))", "0"),
        (p + " (nan? (get 'x (put 'x \(nan) p)))", "true"),
        (p + " (length (values (put 1 (put 'x \(nan) p) (make-hashmap))))", "1")
    ] as [ValueCase])
    func nanFields(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

}
