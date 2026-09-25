import Testing
@testable import Myron

// MARK: - Record Values

@Suite("Record")

struct RecordTests {

    private static func point() throws -> MyronRecordType {
        try MyronRecordType(name: "point", fields: ["x", "y"])
    }

    private static func record(
        _ type: MyronRecordType,
        _ fields: [String: MyronValue]
    ) throws -> MyronValue {
        .record(try MyronRecord(type: type, fields: fields))
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

    private static func nest(
        _ depth: Int,
        in box: MyronRecordType,
        around leaf: MyronValue
    ) -> MyronValue {
        var value = leaf
        for _ in 0..<depth { value = .record(MyronRecord(type: box, contents: [value])) }
        return value
    }

    // MARK: Record Type

    @Test("a record type keeps its fields in declaration order")
    func typeFieldOrder() throws {
        let type = try MyronRecordType(name: "t", fields: ["c", "a", "b"])
        #expect(type.fields == ["c", "a", "b"])
        #expect(type.hasField("a"))
        #expect(!type.hasField("d"))
    }

    @Test("a record type rejects a malformed definition", arguments: [
        ("point", ["x", "x"], .duplicateField("x", "point")),
        ("if", ["x"], .invalidName("if")),
        ("point", ["if"], .invalidName("if")),
        ("", ["x"], .invalidName("")),
        ("point", ["two words"], .invalidName("two words")),
        ("point", ["1"], .invalidName("1"))
    ] as [(String, [String], MyronError.Reason)])
    func typeFailures(_ name: String, _ fields: [String], _ reason: MyronError.Reason) {
        Self.expectReason(reason) { try MyronRecordType(name: name, fields: fields) }
    }

    @Test("a record type compares and hashes by its name and fields")
    func typeStructure() throws {
        let fst = try Self.point()
        let snd = try Self.point()

        #expect(fst == snd)
        #expect(fst.hashValue == snd.hashValue)
        #expect(Set([fst, snd]).count == 1)
        #expect(MyronValue.recordType(fst) == MyronValue.recordType(snd))
        #expect(MyronValue.recordType(fst).hashValue == MyronValue.recordType(snd).hashValue)
    }

    @Test("a record type differing in name, fields or field order is another type", arguments: [
        ("other", ["x", "y"]),
        ("point", ["x", "z"]),
        ("point", ["x", "y", "z"]),
        ("point", ["x"]),
        ("point", []),
        ("point", ["y", "x"])
    ] as [(String, [String])])
    func typeDifferences(_ name: String, _ fields: [String]) throws {
        let other = try MyronRecordType(name: name, fields: fields)
        #expect(try Self.point() != other)
        #expect(Set([try Self.point(), other]).count == 2)
    }

    // MARK: Construction

    @Test("an unset field is nothing")
    func unsetFields() throws {
        let type = try Self.point()
        let record = try MyronRecord(type: type, fields: ["y": .integer(2)])

        #expect(record["x"] == .nothing)
        #expect(record["y"] == .integer(2))
        #expect(record.values == [.nothing, .integer(2)])
    }

    @Test("construction rejects a field the type does not have")
    func constructionFailures() throws {
        let type = try Self.point()
        Self.expectReason(.unexpectedField("z", "point", ["x", "y"])) {
            try MyronRecord(type: type, fields: ["x": .integer(1), "z": .integer(3)])
        }
    }

    // MARK: Swift Accessors

    @Test("the accessors follow declaration order")
    func accessors() throws {
        let type = try MyronRecordType(name: "yx", fields: ["y", "x"])
        let record = try MyronRecord(type: type, fields: ["x": .integer(1), "y": .integer(2)])

        #expect(record.typeName == "yx")
        #expect(record.fields == ["y", "x"])
        #expect(record.values == [.integer(2), .integer(1)])
        #expect(record.pairs.map(\.key) == [.symbol("y"), .symbol("x")])
        #expect(record.pairs.map(\.value) == [.integer(2), .integer(1)])
        #expect(record.dictionary == [.symbol("x"): .integer(1), .symbol("y"): .integer(2)])
        #expect(record["x"] == .integer(1))
        #expect(record["z"] == nil)
    }

    @Test("get and put find a field or throw")
    func operations() throws {
        let type = try Self.point()
        let record = try MyronRecord(type: type, fields: ["x": .integer(1), "y": .integer(2)])

        let next = try record.put(field: "x", value: .integer(10), location: nil)
        #expect(try next.get(field: "x", location: nil) == .integer(10))
        #expect(try record.get(field: "x", location: nil) == .integer(1))

        let reason = MyronError.Reason.unexpectedField("z", "point", ["x", "y"])
        Self.expectReason(reason) { try record.get(field: "z", location: nil) }
        Self.expectReason(reason) {
            try record.put(field: "z", value: .integer(1), location: nil)
        }
    }

    // MARK: Equality

    @Test("records of one type compare by their fields")
    func equality() throws {
        let type = try Self.point()
        let fst = try Self.record(type, ["x": .integer(1), "y": .integer(2)])

        #expect(fst.isEqual(try Self.record(type, ["x": .integer(1), "y": .integer(2)])))
        #expect(!fst.isEqual(try Self.record(type, ["x": .integer(1), "y": .integer(3)])))
        #expect(!fst.isEqual(try Self.record(type, ["x": .integer(2), "y": .integer(1)])))
        #expect(!fst.isEqual(try Self.record(type, ["x": .integer(1)])))
    }

    @Test("records of separately built but matching types compare by their fields")
    func equalityAcrossDefinitions() throws {
        let fields: [String: MyronValue] = ["x": .integer(1), "y": .integer(2)]
        let fst = try Self.record(try Self.point(), fields)
        let snd = try Self.record(try Self.point(), fields)

        #expect(fst.isEqual(snd))
        #expect(fst == snd)
        #expect(fst.hashValue == snd.hashValue)
    }

    // Fields are held by position, so types that differ only in field order
    // must keep their records apart, even where the positions line up.
    @Test("records of types differing in name or field order are never equal")
    func equalityAcrossTypes() throws {
        let xy = try Self.point()
        let yx = try MyronRecordType(name: "point", fields: ["y", "x"])
        let other = try MyronRecordType(name: "other", fields: ["x", "y"])

        let same = MyronRecord(type: xy, contents: [.integer(1), .integer(1)])
        #expect(!MyronValue.record(same).isEqual(.record(MyronRecord(type: yx, contents: [1, 1]))))
        #expect(!MyronValue.record(same).isEqual(.record(MyronRecord(type: other, contents: [1, 1]))))

        let swapped = try Self.record(yx, ["x": .integer(1), "y": .integer(2)])
        #expect(!(try Self.record(xy, ["x": .integer(1), "y": .integer(2)])).isEqual(swapped))
    }

    @Test("a record is never equal to another kind of value")
    func equalityAcrossKinds() throws {
        let type = try Self.point()
        let record = try Self.record(type, ["x": .integer(1), "y": .integer(2)])
        let asHashmap = MyronValue.hashmap(MyronHashmap([
            MyronValue.symbol("x"): MyronValue.integer(1),
            MyronValue.symbol("y"): MyronValue.integer(2)]))

        #expect(!record.isEqual(asHashmap))
        #expect(!record.isEqual(.list([.integer(1), .integer(2)])))
        #expect(!record.isEqual(.recordType(type)))
    }

    @Test("a record holding a nan is not equal to itself")
    func nanIsNotReflexive() throws {
        let record = try Self.record(try Self.point(), ["x": .double(.nan)])
        #expect(!record.isEqual(record))
        #expect(!record.isStorableKey)
    }

    // See the note in `EqualityTests`: depth here is bounded by teardown, not
    // by `isEqual`, which must walk records on its worklist like lists.
    @Test("deep nesting does not overflow the stack")
    func deepNesting() throws {
        let box = try MyronRecordType(name: "box", fields: ["inner"])
        let f = Self.nest(750, in: box, around: .integer(1))
        let s = Self.nest(750, in: box, around: .integer(1))
        let t = Self.nest(750, in: box, around: .integer(2))
        #expect(f.isEqual(s))
        #expect(!f.isEqual(t))
    }

    // MARK: Hashing

    @Test("equal records hash equally")
    func hashing() throws {
        let type = try Self.point()
        let fst = try Self.record(type, ["x": .double(0.0), "y": .list([.integer(1)])])
        let snd = try Self.record(type, ["x": .double(-0.0), "y": .list([.integer(1)])])

        #expect(fst == snd)
        #expect(fst.hashValue == snd.hashValue)
        #expect(Set([fst, snd]).count == 1)

        var byValue = [MyronValue: String]()
        byValue[fst] = "stored"
        #expect(byValue[snd] == "stored")
    }

    // MARK: Kind

    @Test("records and record types have their own kinds")
    func kinds() throws {
        let type = try Self.point()
        #expect(MyronValue.recordType(type).kind == .recordType)
        #expect(try Self.record(type, [:]).kind == .record)
        #expect(MyronValue.Kind.record.description == "record")
        #expect(MyronValue.Kind.recordType.description == "record-type")
    }

    // MARK: Description

    @Test("descriptions list the fields in declaration order")
    func descriptions() throws {
        let type = try MyronRecordType(name: "yx", fields: ["y", "x"])
        let unit = try MyronRecordType(name: "unit", fields: [])

        #expect(type.description == "<record-type: yx y x>")
        #expect(unit.description == "<record-type: unit>")

        let record = try Self.record(type, ["x": .string("a"), "y": .integer(1)])
        #expect(record.description == "<record: yx (y: 1 x: \"a\")>")
        #expect(try Self.record(type, [:]).description
                == "<record: yx (y: <nothing> x: <nothing>)>")
        #expect(try Self.record(unit, [:]).description == "<record: unit ()>")
    }

}
