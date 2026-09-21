import Testing
import Myron // Imported without @testable to exercise only public API.

// MARK: - A Host Type

// A type outside the library, conforming to both directions using only the
// public surface. If a host cannot write this, the protocols are not doing
// their job.

struct Version: Equatable {
    var major: Int
    var minor: Int
}

extension Version: MyronValueConvertible {
    init(myronValue: MyronValue) throws {
        let parts: [Int] = try myronValue.require()
        guard parts.count == 2 else {
            throw MyronHostError("a version needs two parts, got \(parts.count)")
        }
        self.init(major: parts[0], minor: parts[1])
    }
}

extension Version: MyronValueRepresentable {
    var myronValue: MyronValue { [major, minor].myronValue }
}

// MARK: - Value Conversion

@Suite("Value Conversion")

struct ValueConvertibleTests {

    // MARK: Scalars

    @Test("a scalar converts to its Swift counterpart")
    func scalars() throws {
        let boolean: Bool = try MyronValue.boolean(true).require()
        let integer: Int = try MyronValue.integer(7).require()
        let double: Double = try MyronValue.double(1.5).require()
        let string: String = try MyronValue.string("a").require()

        #expect(boolean == true)
        #expect(integer == 7)
        #expect(double == 1.5)
        #expect(string == "a")
    }

    // Matching the probing accessors, which also refuse to stand in for each
    // other.
    @Test("integers and doubles do not convert into each other")
    func noNumericCoercion() {
        #expect(throws: MyronError.self) {
            let _: Double = try MyronValue.integer(1).require()
        }
        #expect(throws: MyronError.self) {
            let _: Int = try MyronValue.double(1).require()
        }
    }

    @Test("the identity conversion yields the value itself")
    func identity() throws {
        let value: MyronValue = try MyronValue.symbol("s").require()

        #expect(value.asSymbol == "s")
    }

    // MARK: Containers

    @Test("a list converts, and nests")
    func lists() throws {
        let flat: [Int] = try MyronValue.list([.integer(1), .integer(2)]).require()
        let nested: [[Int]] = try MyronValue
            .list([.list([.integer(1)]), .list([.integer(2)])])
            .require()
        let values: [MyronValue] = try MyronValue.list([.integer(1), .string("x")]).require()

        #expect(flat == [1, 2])
        #expect(nested == [[1], [2]])
        #expect(values.count == 2)
        #expect(values[1].asString == "x")
    }

    @Test("a hashmap converts, and nests")
    func hashmaps() throws {
        let flat: [String: Int] = try MyronValue.hashmap(["a": 1, "b": 2]).require()
        let nested: [String: [Int]] = try MyronValue.hashmap(["a": [1, 2]]).require()
        let values: [String: MyronValue] = try MyronValue.hashmap(["a": 1]).require()

        #expect(flat == ["a": 1, "b": 2])
        #expect(nested == ["a": [1, 2]])
        #expect(values["a"]?.asInteger == 1)
    }

    @Test("an empty container converts to an empty collection")
    func emptyContainers() throws {
        let list: [Int] = try MyronValue.list([]).require()
        let hashmap: [String: Int] = try MyronValue.hashmap([:]).require()

        #expect(list.isEmpty)
        #expect(hashmap.isEmpty)
    }

    @Test("the native container types convert")
    func nativeContainers() throws {
        let set: MyronSet = try MyronValue.set([1, 2]).require()
        let hashmap: MyronHashmap = try MyronValue.hashmap(["a": 1]).require()

        #expect(set.count == 2)
        #expect(hashmap["a"]?.asInteger == 1)
    }

    // MARK: Optionals

    @Test("an optional takes nothing as nil")
    func optionals() throws {
        let absent: Int? = try MyronValue.nothing.require()
        let present: Int? = try MyronValue.integer(5).require()
        let inList: [Int?] = try MyronValue.list([.integer(1), .nothing]).require()

        #expect(absent == nil)
        #expect(present == 5)
        #expect(inList == [1, nil])
    }

    @Test("a non-optional refuses nothing")
    func nonOptionalRefusesNothing() {
        #expect(throws: MyronError.self) {
            let _: Int = try MyronValue.nothing.require()
        }
    }

    // MARK: Leniency

    // `unwrapElements` accepts a list or a set, so the Swift collection the host
    // asks for decides the shape rather than the Myron kind it came from.
    @Test("a list and a set convert into either Swift collection")
    func listAndSetInterchange() throws {
        let fromSet: [Int] = try MyronValue.set([1, 2]).require()
        let fromList: Set<Int> = try MyronValue.list([.integer(1), .integer(2)]).require()

        #expect(fromSet.sorted() == [1, 2])
        #expect(fromList == [1, 2])
    }

    // The native set takes a list too, so it agrees with Swift's Set rather
    // than insisting on the exact Myron kind.
    @Test("the native set accepts a list as readily as Swift's Set does")
    func nativeSetMatchesSwiftSet() throws {
        let native: MyronSet = try MyronValue.list([.integer(1), .integer(2)]).require()
        let swift: Set<Int> = try MyronValue.list([.integer(1), .integer(2)]).require()

        #expect(native.count == 2)
        #expect(native.contains(.integer(1)))
        #expect(native.count == swift.count)
    }

    @Test("the native set collapses duplicates from a list, as Swift's Set does")
    func nativeSetCollapsesDuplicates() throws {
        let source = MyronValue.list([.integer(1), .integer(1), .integer(2)])
        let native: MyronSet = try source.require()
        let swift: Set<Int> = try source.require()

        #expect(native.count == 2)
        #expect(native.count == swift.count)
    }

    // Swift's own Set semantics, and consistent with the hashmap literal rule
    // that a duplicate key keeps the first.
    @Test("converting a list with duplicates to a set collapses them")
    func setCollapsesDuplicates() throws {
        let set: Set<Int> = try MyronValue
            .list([.integer(1), .integer(1), .integer(2)])
            .require()

        #expect(set.count == 2)
    }

    // MARK: Failures

    @Test("a mismatch reports what was got and what was expected")
    func mismatchReason() {
        let error = #expect(throws: MyronError.self) {
            let _: Int = try MyronValue.string("a").require()
        }

        #expect(error?.reason == .unexpectedType(.string, [.integer]))
    }

    // The throwing requirement is what buys this. A failable initialiser would
    // collapse the inner failure into the container's own type mismatch.
    @Test("a nested mismatch names the element type, not the container")
    func nestedMismatchNamesTheElement() {
        let error = #expect(throws: MyronError.self) {
            let _: [Int] = try MyronValue.list([.integer(1), .string("x")]).require()
        }

        #expect(error?.reason == .unexpectedType(.string, [.integer]))
    }

    @Test("a mismatch deep inside a hashmap names the innermost type")
    func deepMismatchNamesTheInnermost() {
        let error = #expect(throws: MyronError.self) {
            let _: [String: [Int]] = try MyronValue
                .hashmap(["a": [1, "x"] as MyronValue])
                .require()
        }

        #expect(error?.reason == .unexpectedType(.string, [.integer]))
    }

    @Test("asking a non-container for a container reports the container kinds")
    func wrongContainerKind() {
        let listError = #expect(throws: MyronError.self) {
            let _: [Int] = try MyronValue.integer(1).require()
        }
        let mapError = #expect(throws: MyronError.self) {
            let _: [String: Int] = try MyronValue.integer(1).require()
        }

        #expect(listError?.reason == .unexpectedType(.integer, [.list, .set]))
        #expect(mapError?.reason == .unexpectedType(.integer, [.hashmap]))
    }

    // Conversions throw without a location. Inside a host primitive the call
    // site is stamped on the way out, but on its own there is nothing to point
    // at.
    @Test("a conversion outside a host body carries no location")
    func noLocationOutsideAHostBody() {
        let error = #expect(throws: MyronError.self) {
            let _: Int = try MyronValue.string("a").require()
        }

        #expect(error?.location == nil)
    }

    // MARK: The Named Accessors

    @Test("the named accessors need no annotation")
    func namedAccessors() throws {
        #expect(try MyronValue.boolean(true).requireBoolean() == true)
        #expect(try MyronValue.integer(1).requireInteger() == 1)
        #expect(try MyronValue.double(1.5).requireDouble() == 1.5)
        #expect(try MyronValue.string("s").requireString() == "s")
        #expect(try MyronValue.symbol("y").requireSymbol() == "y")
    }

    @Test("a named accessor refuses the wrong kind")
    func namedAccessorsRefuseTheWrongKind() {
        #expect(throws: MyronError.self) { try MyronValue.integer(1).requireBoolean() }
        #expect(throws: MyronError.self) { try MyronValue.string("1").requireInteger() }
        #expect(throws: MyronError.self) { try MyronValue.symbol("s").requireString() }
    }

    // Two Myron kinds map to one Swift type, so the generic conversion has to
    // pick one — it takes the string kind, and a symbol needs its own accessor.
    @Test("a symbol converts only through its named accessor")
    func symbolNeedsItsNamedAccessor() throws {
        #expect(try MyronValue.symbol("y").requireSymbol() == "y")
        #expect(throws: MyronError.self) {
            let _: String = try MyronValue.symbol("y").require()
        }
    }

    // MARK: Round Trips

    @Test("Swift values round trip out to Myron and back")
    func roundTrips() throws {
        let integer: Int = try 7.myronValue.require()
        let double: Double = try 1.5.myronValue.require()
        let string: String = try "s".myronValue.require()
        let boolean: Bool = try true.myronValue.require()
        let list: [Int] = try [1, 2].myronValue.require()
        let dictionary: [String: Int] = try ["a": 1].myronValue.require()
        let set: Set<Int> = try Set([1, 2]).myronValue.require()

        #expect(integer == 7)
        #expect(double == 1.5)
        #expect(string == "s")
        #expect(boolean == true)
        #expect(list == [1, 2])
        #expect(dictionary == ["a": 1])
        #expect(set == [1, 2])
    }

    @Test("a value built in Myron converts through the Swift API")
    func outOfMyron() throws {
        let result = MyronSession().eval("(make-hashmap '((\"a\" 1) (\"b\" 2)))")
        let value = try #require(result.asSuccess)
        let dictionary: [String: Int] = try value.require()

        #expect(dictionary == ["a": 1, "b": 2])
    }

    // MARK: A Host Type

    @Test("a host type converts in both directions")
    func hostTypeBothDirections() throws {
        let version: Version = try MyronValue.list([.integer(1), .integer(2)]).require()

        #expect(version == Version(major: 1, minor: 2))
        #expect(version.myronValue.description == "(1 2)")
    }

    @Test("a host type nests inside the container conversions")
    func hostTypeNests() throws {
        let source = MyronValue.list([
            .list([.integer(1), .integer(0)]),
            .list([.integer(2), .integer(1)])
        ])
        let versions: [Version] = try source.require()

        #expect(versions == [Version(major: 1, minor: 0), Version(major: 2, minor: 1)])
    }

    @Test("a host type's own error surfaces as a host error")
    func hostTypeOwnError() {
        let error = #expect(throws: MyronHostError.self) {
            let _: Version = try MyronValue.list([.integer(1)]).require()
        }

        #expect(error?.description == "a version needs two parts, got 1")
    }

    @Test("a host type crosses the boundary through a primitive")
    func hostTypeThroughAPrimitive() throws {
        let session = MyronSession()
        try session.define("bump") { value in
            let version: Version = try value.require()
            return Version(major: version.major, minor: version.minor + 1)
        }

        #expect(session.eval("(bump '(1 2))").asSuccess?.description == "(1 3)")
    }

    @Test("a host type's error reaches Myron as a located host error")
    func hostTypeErrorThroughAPrimitive() throws {
        let session = MyronSession()
        try session.define("bump") { value in
            let version: Version = try value.require()
            return version
        }
        let error = try #require(session.eval("(bump '(1))").asFailure?.first)

        #expect(error.reason == .hostError("a version needs two parts, got 1"))
        #expect(error.location != nil)
    }

}
