import Testing
import Myron // Imported without @testable to exercise only public API.

// MARK: - Swift Interoperability

@Suite("Swift Interoperability")

struct SwiftInteropTests {

    // MARK: Reading a Value

    @Test("a value yields its Swift counterpart")
    func valueAccessors() {
        #expect(MyronValue.boolean(true).asBoolean == true)
        #expect(MyronValue.integer(7).asInteger == 7)
        #expect(MyronValue.double(1.5).asDouble == 1.5)
        #expect(MyronValue.string("a").asString == "a")
        #expect(MyronValue.symbol("s").asSymbol == "s")
        #expect(MyronValue.list([.integer(1)]).asList?.count == 1)
        #expect(MyronValue.hashmap(["a": 1]).asHashmap?.count == 1)
    }

    @Test("an accessor for the wrong case is nil")
    func valueAccessorsMiss() {
        let value = MyronValue.integer(1)
        #expect(value.asBoolean == nil)
        #expect(value.asDouble == nil)
        #expect(value.asString == nil)
        #expect(value.asSymbol == nil)
        #expect(value.asList == nil)
        #expect(value.asHashmap == nil)
        #expect(MyronValue.nothing.asInteger == nil)
    }

    @Test("integers and doubles do not stand in for each other")
    func noNumericCoercion() {
        #expect(MyronValue.integer(1).asDouble == nil)
        #expect(MyronValue.double(1).asInteger == nil)
    }

    @Test("every value reports a kind")
    func valueKind() {
        #expect(MyronValue.boolean(true).kind == .boolean)
        #expect(MyronValue.nothing.kind == .nothing)
        #expect(MyronValue.list([]).kind == .list)
        #expect(MyronValue.hashmap([:]).kind == .hashmap)
        #expect(MyronValue.integer(1).kind != MyronValue.double(1).kind)
    }

    // MARK: Building a Value

    @Test("Swift scalars represent themselves")
    func scalarsRepresentable() {
        #expect(true.myronValue.asBoolean == true)
        #expect(7.myronValue.asInteger == 7)
        #expect(1.5.myronValue.asDouble == 1.5)
        #expect("a".myronValue.asString == "a")
    }

    @Test("a value represents itself")
    func valueIsRepresentable() {
        let value = MyronValue.symbol("s")
        #expect(value.myronValue.asSymbol == "s")
    }

    @Test("an optional represents its wrapped value, or nothing")
    func optionalRepresentable() {
        #expect(Optional<Int>.some(3).myronValue.asInteger == 3)
        #expect(Optional<Int>.none.myronValue.kind == .nothing)
    }

    @Test("an array becomes a list")
    func arrayRepresentable() {
        #expect([1, 2, 3].myronValue.description == "(1 2 3)")
        #expect([String]().myronValue.description == "()")
        #expect([[1, 2], [3]].myronValue.description == "((1 2) (3))")
    }

    @Test("a dictionary becomes a hashmap")
    func dictionaryRepresentable() {
        let hashmap = ["a": 1, "b": 2].myronValue.asHashmap
        #expect(hashmap?.count == 2)
        #expect(hashmap?["a"]?.asInteger == 1)
        #expect(hashmap?["z"] == nil)
    }

    @Test("a nil dictionary value is dropped rather than stored")
    func dictionaryDropsNothing() {
        let absent: Int? = nil
        let hashmap = ["a": 1, "b": absent].myronValue.asHashmap
        #expect(hashmap?.count == 1)
        #expect(hashmap?["b"] == nil)
    }

    // MARK: Value literals

    @Test("a value can be written as a literal")
    func valueLiterals() {
        let nothing: MyronValue = nil
        let boolean: MyronValue = true
        let integer: MyronValue = 42
        let double: MyronValue = 1.5
        let string: MyronValue = "a"

        #expect(nothing.kind == .nothing)
        #expect(boolean.asBoolean == true)
        #expect(integer.asInteger == 42)
        #expect(double.asDouble == 1.5)
        #expect(string.asString == "a")
    }

    @Test("an array literal mixes Swift values, Myron values and nesting")
    func arrayLiteral() {
        let n = 5
        let existing = MyronValue.string("v")
        let list: MyronValue = [1, "two", true, n, existing, [1, 2]]

        #expect(list.asList?.count == 6)
        #expect(list.asList?[3].asInteger == 5)
        #expect(list.asList?[4].asString == "v")
        #expect(list.asList?[5].kind == .list)
    }

    @Test("a dictionary literal makes a hashmap")
    func valueDictionaryLiteral() {
        let value: MyronValue = ["a": 1, "b": "two", "c": true]

        #expect(value.kind == .hashmap)
        #expect(value.asHashmap?.count == 3)
        #expect(value.asHashmap?["a"]?.asInteger == 1)
        #expect(value.asHashmap?["b"]?.asString == "two")
        #expect(value.asHashmap?["c"]?.asBoolean == true)
    }

    @Test("a dictionary literal takes variables and nests")
    func valueDictionaryLiteralVariables() {
        let key = "k"
        let count = 3
        let value: MyronValue = ["tags": ["a", "b"], "limits": ["max": 10], key: count]

        #expect(value.asHashmap?.count == 3)
        #expect(value.asHashmap?["k"]?.asInteger == 3)
        #expect(value.asHashmap?["tags"]?.kind == .list)
        #expect(value.asHashmap?["limits"]?.asHashmap?["max"]?.asInteger == 10)
    }

    @Test("the two dictionary literals accept the same keys")
    func dictionaryLiteralsAgreeOnKeys() {
        // Both take any MyronKeyRepresentable, so a key held in a variable works
        // in either position.
        let key = "k"
        let hashmap: MyronHashmap = [key: 1]
        let value: MyronValue = [key: 1]

        #expect(hashmap["k"]?.asInteger == 1)
        #expect(value.asHashmap?["k"]?.asInteger == 1)
        #expect(MyronValue.hashmap(hashmap).asHashmap?.count == value.asHashmap?.count)
    }

    @Test("a dictionary literal follows the hashmap literal rules")
    func valueDictionaryLiteralRules() {
        let absent: Int? = nil
        let dropped: MyronValue = ["a": 1, "b": absent]
        let duplicated: MyronValue = ["a": 1, "a": 2]
        let empty: MyronValue = [:]

        #expect(dropped.asHashmap?.count == 1)
        #expect(dropped.asHashmap?["b"] == nil)
        #expect(duplicated.asHashmap?["a"]?.asInteger == 1)
        #expect(empty.kind == .hashmap)
        #expect(empty.asHashmap?.isEmpty == true)
    }

    @Test("a MyronKey can be written as a literal key")
    func valueDictionaryLiteralMyronKey() {
        let value: MyronValue = [MyronKey.string("m"): 1, MyronKey.double(1.5): 2]

        #expect(value.asHashmap?["m"]?.asInteger == 1)
        #expect(value.asHashmap?[.double(1.5)]?.asInteger == 2)
    }

    // MARK: MyronKey

    @Test("a key can be made from a value")
    func keyFromValue() throws {
        #expect(try MyronKey(.integer(1)) == .integer(1))
        #expect(try MyronKey(.string("a")) == .string("a"))
        #expect(try MyronKey(.boolean(true)) == .boolean(true))
        #expect(try MyronKey(.double(1.5)) == .double(1.5))
    }

    @Test("a key rejects values that cannot be keys")
    func keyRejectsValues() {
        #expect(throws: MyronError.self) { try MyronKey(.symbol("s")) }
        #expect(throws: MyronError.self) { try MyronKey(.list([])) }
        #expect(throws: MyronError.self) { try MyronKey(.nothing) }
        #expect(throws: MyronError.self) { try MyronKey(.double(.nan)) }
        #expect(throws: MyronError.self) { try MyronKey(.double(.infinity)) }
    }

    @Test("a key round trips through its value")
    func keyRoundTrip() throws {
        let key = MyronKey.string("a")
        #expect(try MyronKey(key.value) == key)
        #expect(key.value.asString == "a")
    }

    @Test("a key can be written as a literal")
    func keyLiterals() {
        let boolean: MyronKey = true
        let integer: MyronKey = 42
        let double: MyronKey = 1.5
        let string: MyronKey = "a"

        #expect(boolean == .boolean(true))
        #expect(integer == .integer(42))
        #expect(double == .double(1.5))
        #expect(string == .string("a"))
    }

    @Test("a key represents itself")
    func keyIsRepresentable() {
        #expect(MyronKey.integer(1).myronKey == .integer(1))
        #expect(1.myronKey == .integer(1))
        #expect("a".myronKey == .string("a"))
        #expect(true.myronKey == .boolean(true))
    }

    @Test("keys of different types are distinct")
    func keysAreTyped() {
        #expect(MyronKey.integer(1) != MyronKey.double(1))
        #expect(MyronKey.integer(1) != MyronKey.string("1"))
    }

    // MARK: Hashmap from a Swift dictionary

    @Test("a hashmap can be built from a Swift dictionary")
    func hashmapFromSwiftDictionary() throws {
        let hashmap = try MyronHashmap(["a": 1, "b": 2])
        #expect(hashmap.count == 2)
        #expect(hashmap["a"]?.asInteger == 1)
        #expect(hashmap["z"] == nil)
    }

    @Test("a hashmap can be built from Myron keys and values")
    func hashmapFromMyronDictionary() throws {
        let hashmap = try MyronHashmap([MyronKey.string("a"): MyronValue.integer(1)])
        #expect(hashmap.count == 1)
        #expect(hashmap["a"]?.asInteger == 1)
    }

    @Test("building from Myron types rejects a stored nothing")
    func hashmapRejectsNothing() {
        #expect(throws: MyronError.self) {
            try MyronHashmap([MyronKey.string("a"): MyronValue.nothing])
        }
    }

    @Test("building from Myron types rejects a non-finite key")
    func hashmapRejectsNonFiniteKey() {
        #expect(throws: MyronError.self) {
            try MyronHashmap([MyronKey.double(.nan): MyronValue.integer(1)])
        }
        #expect(throws: MyronError.self) {
            try MyronHashmap([MyronKey.double(.infinity): MyronValue.integer(1)])
        }
    }

    @Test("building from Swift types drops a nil value")
    func hashmapDropsNilValue() throws {
        let absent: Int? = nil
        let hashmap = try MyronHashmap(["a": 1, "b": absent])
        #expect(hashmap.count == 1)
        #expect(hashmap["b"] == nil)
    }

    // MARK: Hashmap accessors

    @Test("a hashmap reports its size")
    func hashmapSize() throws {
        #expect(try MyronHashmap([String: Int]()).isEmpty)
        #expect(try MyronHashmap([String: Int]()).count == 0)
        #expect(try !MyronHashmap(["a": 1]).isEmpty)
        #expect(try MyronHashmap(["a": 1, "b": 2]).count == 2)
    }

    @Test("a single entry reads back predictably")
    func singleEntryAccessors() throws {
        let hashmap = try MyronHashmap(["a": 1])
        #expect(hashmap.keys == [.string("a")])
        #expect(hashmap.values.first?.asInteger == 1)
        #expect(hashmap.pairs.first?.key == .string("a"))
        #expect(hashmap.pairs.first?.value.asInteger == 1)
        #expect(hashmap.dictionary.keys.map { $0 } == [.string("a")])
        #expect(hashmap.dictionary[.string("a")]?.asInteger == 1)
        #expect(hashmap.description == "#((\"a\" 1))")
    }

    @Test("every entry is reachable regardless of order")
    func allEntriesReachable() throws {
        let hashmap = try MyronHashmap(["a": 1, "b": 2, "c": 3])
        #expect(hashmap.keys.count == 3)
        #expect(hashmap.values.count == 3)
        #expect(hashmap.pairs.count == 3)
        #expect(hashmap.dictionary.count == 3)
        #expect(hashmap.keys.contains(.string("b")))
        #expect(hashmap.values.compactMap(\.asInteger).sorted() == [1, 2, 3])
    }

    @Test("a hashmap round trips through its dictionary")
    func hashmapRoundTrip() throws {
        let hashmap = try MyronHashmap(["a": 1, "b": 2])
        let again = try MyronHashmap(hashmap.dictionary)
        #expect(again.count == hashmap.count)
        #expect(again["a"]?.asInteger == 1)
        #expect(again["b"]?.asInteger == 2)
    }

    // MARK: Hashmap as a Sequence

    @Test("a hashmap iterates as key and value")
    func hashmapIteration() throws {
        let hashmap = try MyronHashmap(["a": 1, "b": 2])
        var seen = [MyronKey: Int]()

        for (key, value) in hashmap {
            seen[key] = value.asInteger
        }

        #expect(seen == [.string("a"): 1, .string("b"): 2])
    }

    @Test("sequence operations are available")
    func hashmapSequenceOperations() throws {
        let hashmap = try MyronHashmap(["a": 1, "b": 2, "c": 3])
        #expect(hashmap.map(\.key).count == 3)
        #expect(hashmap.filter { $0.value.asInteger == 2 }.count == 1)
        #expect(hashmap.contains { $0.key == .string("c") })
        #expect(hashmap.compactMap { $0.value.asInteger }.sorted() == [1, 2, 3])
    }

    // MARK: Hashmap literals

    @Test("a hashmap literal takes Swift literals of mixed type")
    func hashmapLiteralOfLiterals() {
        let hashmap: MyronHashmap = ["a": 1, "b": "two", "c": true, 4: 1.5]
        #expect(hashmap.count == 4)
        #expect(hashmap["a"]?.asInteger == 1)
        #expect(hashmap["b"]?.asString == "two")
        #expect(hashmap["c"]?.asBoolean == true)
        #expect(hashmap[4]?.asDouble == 1.5)
    }

    @Test("a hashmap literal takes variables, not just literals")
    func hashmapLiteralOfVariables() {
        let key = "k"
        let number = 5
        let hashmap: MyronHashmap = [key: number]

        #expect(hashmap.count == 1)
        #expect(hashmap["k"]?.asInteger == 5)
    }

    @Test("a hashmap literal takes Myron keys and values")
    func hashmapLiteralOfMyronTypes() {
        let key = MyronKey.string("k")
        let value = MyronValue.integer(9)
        let hashmap: MyronHashmap = [key: value]

        #expect(hashmap.count == 1)
        #expect(hashmap["k"]?.asInteger == 9)
    }

    @Test("a hashmap literal nests Swift collections")
    func hashmapLiteralNesting() {
        let hashmap: MyronHashmap = ["list": [1, 2], "map": ["n": 1]]
        #expect(hashmap.count == 2)
        #expect(hashmap["list"]?.kind == .list)
        #expect(hashmap["map"]?.kind == .hashmap)
        #expect(hashmap["map"]?.asHashmap?["n"]?.asInteger == 1)
    }

    @Test("a hashmap literal drops an absent optional and keeps a present one")
    func hashmapLiteralOptionals() {
        let absent: Int? = nil
        let present: Int? = 7
        let hashmap: MyronHashmap = ["x": absent, "y": present, "z": 1]

        #expect(hashmap.count == 2)
        #expect(hashmap["x"] == nil)
        #expect(hashmap["y"]?.asInteger == 7)
    }

    @Test("a duplicated literal key keeps the first")
    func hashmapLiteralDuplicates() {
        let hashmap: MyronHashmap = ["a": 1, "a": 2]
        #expect(hashmap.count == 1)
        #expect(hashmap["a"]?.asInteger == 1)
    }

    @Test("an empty hashmap literal is empty")
    func hashmapLiteralEmpty() {
        let hashmap: MyronHashmap = [:]
        #expect(hashmap.isEmpty)
    }

    // MARK: Session results

    @Test("a successful evaluation reports success")
    func resultSuccess() {
        let result = MyronSession().eval("(+ 1 2)")
        #expect(result.isSuccess)
        #expect(!result.isFailure)
        #expect(!result.isNothing)
        #expect(result.asSuccess?.asInteger == 3)
        #expect(result.asFailure == nil)
    }

    @Test("a failed evaluation reports its errors")
    func resultFailure() {
        let result = MyronSession().eval("(+ 1 undefined)")
        #expect(result.isFailure)
        #expect(!result.isSuccess)
        #expect(result.asSuccess == nil)
        #expect(result.asFailure?.isEmpty == false)
        #expect(result.asFailure?.first?.reason == .unrecognisedSymbol)
    }

    @Test("an empty source reports nothing")
    func resultNothing() {
        let result = MyronSession().eval("   ; just a comment")
        #expect(result.isNothing)
        #expect(!result.isSuccess)
        #expect(!result.isFailure)
    }

    // MARK: Crossing the boundary

    @Test("a hashmap built in Myron reads back through the Swift API")
    func hashmapOutOfMyron() throws {
        let result = MyronSession().eval("(make-hashmap '((\"a\" 1) (\"b\" 2)))")
        let hashmap = try #require(result.asSuccess?.asHashmap)

        #expect(hashmap.count == 2)
        #expect(hashmap["a"]?.asInteger == 1)
        #expect(hashmap["b"]?.asInteger == 2)
        #expect(hashmap.keys.contains(.string("a")))
    }

    @Test("a list built in Myron reads back as Swift values")
    func listOutOfMyron() throws {
        let result = MyronSession().eval("'(1 \"two\" true (3))")
        let list = try #require(result.asSuccess?.asList)

        #expect(list.count == 4)
        #expect(list[0].asInteger == 1)
        #expect(list[1].asString == "two")
        #expect(list[2].asBoolean == true)
        #expect(list[3].asList?.first?.asInteger == 3)
    }

    @Test("a nested hashmap survives the round trip out of Myron")
    func nestedOutOfMyron() throws {
        let source = "(put \"inner\" (make-hashmap '((\"n\" 1))) (make-hashmap))"
        let result = MyronSession().eval(source)
        let outer = try #require(result.asSuccess?.asHashmap)
        let inner = try #require(outer["inner"]?.asHashmap)

        #expect(inner["n"]?.asInteger == 1)
    }

}
