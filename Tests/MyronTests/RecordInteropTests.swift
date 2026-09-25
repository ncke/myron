import Testing
import Myron // Imported without @testable to exercise only public API.

// MARK: - Record Interoperability

@Suite("Record Interoperability")

struct RecordInteropTests {

    private static func point() throws -> MyronRecordType {
        try MyronRecordType(name: "point", fields: "x", "y")
    }

    private static func expectReason(
        _ reason: MyronError.Reason,
        sourceLocation: SourceLocation = #_sourceLocation,
        _ body: () throws -> Any
    ) {
        let error = #expect(throws: MyronError.self, sourceLocation: sourceLocation) {
            _ = try body()
        }

        #expect(error?.reason == reason, sourceLocation: sourceLocation)
    }

    // MARK: Building

    @Test("a record type takes its fields as an array or a variadic list")
    func typeInitialisers() throws {
        let fromArray = try MyronRecordType(name: "point", fields: ["x", "y"])
        let fromVariadic = try MyronRecordType(name: "point", fields: "x", "y")

        #expect(fromArray.name == "point")
        #expect(fromArray.fields == fromVariadic.fields)
        #expect(fromArray == fromVariadic)
        #expect(try MyronRecordType(name: "unit").fields.isEmpty)
    }

    @Test("a record is built by field name or by position")
    func recordInitialisers() throws {
        let type = try Self.point()
        let byName = try MyronRecord(type: type, fields: ["x": 1, "y": 2])
        let byArray = try MyronRecord(type: type, values: [1, 2])
        let byVariadic = try MyronRecord(type: type, values: 1, 2)

        #expect(byName == byArray)
        #expect(byName == byVariadic)
        #expect(byName.values == [1, 2])
    }

    @Test("building by name leaves an unnamed field nothing")
    func partialByName() throws {
        let record = try MyronRecord(type: try Self.point(), fields: ["y": 2])
        #expect(record.values == [nil, 2])
    }

    @Test("building by position wants a value for every field")
    func positionalArity() throws {
        let type = try Self.point()
        let unit = try MyronRecordType(name: "unit")

        #expect(throws: MyronError.self) { try MyronRecord(type: type, values: 1) }
        #expect(throws: MyronError.self) { try MyronRecord(type: type, values: 1, 2, 3) }
        #expect(throws: MyronError.self) { try MyronRecord(type: unit, values: 1) }
        #expect(try MyronRecord(type: unit, values: []).values.isEmpty)
    }

    // An array literal is taken as the values themselves, so a list bound for a
    // single field must be spelled as a value.
    @Test("an array literal gives the values, not a list for one field")
    func arrayLiteralIsTheValues() throws {
        let box = try MyronRecordType(name: "box", fields: "inner")

        #expect(throws: MyronError.self) { try MyronRecord(type: box, values: [1, 2]) }

        let boxed = try MyronRecord(type: box, values: .list([1, 2]))
        #expect(boxed["inner"] == .list([1, 2]))
    }

    @Test("building rejects a field the type does not have")
    func unknownField() throws {
        Self.expectReason(.unexpectedField("z", "point", ["x", "y"])) {
            try MyronRecord(type: try Self.point(), fields: ["z": 1])
        }
    }

    // MARK: Reading & Writing

    @Test("a record reads back its type and fields")
    func reading() throws {
        let type = try Self.point()
        let record = try MyronRecord(type: type, values: 1, 2)

        #expect(record.type == type)
        #expect(record.typeName == "point")
        #expect(record.fields == ["x", "y"])
        #expect(record.hasField("x"))
        #expect(!record.hasField("z"))
        #expect(record["x"] == 1)
        #expect(record["z"] == nil)
        #expect(try record.get(field: "y") == 2)
        #expect(record.pairs.map(\.key) == [.symbol("x"), .symbol("y")])
        #expect(record.dictionary == [.symbol("x"): 1, .symbol("y"): 2])
    }

    @Test("put gives a new record and leaves the original alone")
    func writing() throws {
        let record = try MyronRecord(type: try Self.point(), values: 1, 2)
        let next = try record.put(field: "x", value: 10)

        #expect(try next.get(field: "x") == 10)
        #expect(try record.get(field: "x") == 1)
        #expect(next.type == record.type)
    }

    @Test("get and put reject a field the record does not have")
    func unknownFieldAccess() throws {
        let record = try MyronRecord(type: try Self.point(), values: 1, 2)
        let reason = MyronError.Reason.unexpectedField("z", "point", ["x", "y"])

        Self.expectReason(reason) { try record.get(field: "z") }
        Self.expectReason(reason) { try record.put(field: "z", value: 1) }
    }

    @Test("isa checks a record against a type by its name and fields")
    func isa() throws {
        let record = try MyronRecord(type: try Self.point(), values: 1, 2)

        #expect(record.isa(type: try Self.point()))
        #expect(!record.isa(type: try MyronRecordType(name: "other", fields: "x", "y")))
        #expect(!record.isa(type: try MyronRecordType(name: "point", fields: "y", "x")))
        #expect(!record.isa(type: try MyronRecordType(name: "point", fields: "x", "y", "z")))
    }

    // MARK: Conversion

    @Test("records and record types convert to and from values")
    func conversion() throws {
        let type = try Self.point()
        let record = try MyronRecord(type: type, values: 1, 2)

        #expect(record.myronValue == .record(record))
        #expect(type.myronValue == .recordType(type))
        #expect(record.myronValue.kind == .record)
        #expect(type.myronValue.kind == .recordType)

        #expect(record.myronValue.asRecord == record)
        #expect(try record.myronValue.requireRecord() == record)
        #expect(try record.myronValue.require() as MyronRecord == record)
        #expect(try [record, record].myronValue.require() as [MyronRecord] == [record, record])
    }

    @Test("a record type converts back to the same type")
    func recordTypeIdentity() throws {
        let type = try Self.point()

        #expect(type.myronValue.asRecordType == type)
        #expect(try type.myronValue.requireRecordType() == type)
        #expect(try type.myronValue.require() as MyronRecordType == type)
        #expect(try [type].myronValue.require() as [MyronRecordType] == [type])
    }

    // A host shares its types with Myron by capturing them in the closures it
    // defines, which must be sendable.
    @Test("a record type is sendable")
    func sendable() throws {
        let type: any Sendable = try Self.point()
        #expect(type is MyronRecordType)
    }

    @Test("converting the wrong kind of value throws")
    func conversionFailures() throws {
        Self.expectReason(.unexpectedType(.integer, [.record])) {
            try MyronValue.integer(1).requireRecord()
        }
        Self.expectReason(.unexpectedType(.integer, [.recordType])) {
            try MyronValue.integer(1).requireRecordType()
        }

        let record = try MyronRecord(type: try Self.point(), values: 1, 2)
        Self.expectReason(.unexpectedType(.record, [.recordType])) {
            try record.myronValue.requireRecordType()
        }
    }

    // MARK: Sessions

    @Test("a type built by the host is shared with Myron code")
    func hostOwnedType() throws {
        let type = try Self.point()
        let session = MyronSession()
        session.set("point", to: type.myronValue)

        let made = try #require(session.eval("(make-record point 1 2)").asSuccess)
        let record = try made.requireRecord()
        #expect(record.isa(type: type))
        #expect(try record.get(field: "x") == 1)

        let hostMade = try MyronRecord(type: type, values: 1, 2)
        session.set("q", to: hostMade.myronValue)
        #expect(session.eval("(record-isa? point q)").asSuccess == true)
        #expect(session.eval("(eq q (make-record point 1 2))").asSuccess == true)
    }

    @Test("a type defined in Myron is the host's when its name and fields agree")
    func myronOwnedType() throws {
        let type = try Self.point()
        let session = MyronSession()

        let same = try #require(
            session.eval("(make-record (make-record-type 'point '(x y)) 1 2)").asSuccess)
        #expect(try same.requireRecord().isa(type: type))

        let reordered = try #require(
            session.eval("(make-record (make-record-type 'point '(y x)) 2 1)").asSuccess)
        #expect(try !reordered.requireRecord().isa(type: type))
    }

    // Records carry no tie to the session that made them, so they can move
    // between sessions, or across the wire, and still match.
    @Test("a record made in one session matches in another")
    func acrossSessions() throws {
        let fst = MyronSession()
        let snd = MyronSession()
        _ = fst.eval("(define point (make-record-type 'point '(x y)))")
        _ = snd.eval("(define point (make-record-type 'point '(x y)))")

        let record = try #require(fst.eval("(make-record point 1 2)").asSuccess)
        snd.set("p", to: record)

        #expect(snd.eval("(record-isa? point p)").asSuccess == true)
        #expect(snd.eval("(eq p (make-record point 1 2))").asSuccess == true)
        #expect(snd.eval("(get 'y p)").asSuccess == 2)
        #expect(try #require(snd.query("point")) == #require(fst.query("point")))
    }

    @Test("a type defined in Myron can be read back by the host")
    func queryType() throws {
        let session = MyronSession()
        _ = session.eval("(define point (make-record-type 'point '(x y)))")
        _ = session.eval("(define p (make-record point 1 2))")

        let type = try #require(session.query("point")).requireRecordType()
        let record = try #require(session.query("p")).requireRecord()
        #expect(record.isa(type: type))
        #expect(type.fields == ["x", "y"])
    }

    @Test("a host primitive takes and gives records")
    func hostPrimitives() throws {
        let type = try Self.point()
        let session = MyronSession()
        session.set("point", to: type.myronValue)

        try session.define("origin") { () in
            try MyronRecord(type: type, values: 0, 0)
        }

        try session.define("sum") { (value: MyronValue) in
            let record = try value.requireRecord()
            guard record.isa(type: type) else {
                return MyronValue.nothing
            }

            let x = try record.get(field: "x").requireInteger()
            let y = try record.get(field: "y").requireInteger()
            return x + y
        }

        #expect(session.eval("(record-isa? point (origin))").asSuccess == true)
        #expect(session.eval("(sum (make-record point 3 4))").asSuccess == 7)
        #expect(session.eval("(sum (put 'x 10 (origin)))").asSuccess == 10)

        let same = "(make-record (make-record-type 'point '(x y)) 3 4)"
        #expect(session.eval("(sum \(same))").asSuccess == 7)

        let other = "(make-record (make-record-type 'vector '(x y)) 3 4)"
        #expect(session.eval("(sum \(other))").asSuccess == .nothing)
        #expect(session.eval("(sum 5)").isFailure)
    }

}
