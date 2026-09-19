import Testing
@testable import Myron

// MARK: - Hashable

@Suite("Hashable")

struct HashableTests {

    private func hashmap(_ pairs: [(MyronValue, MyronValue)]) -> MyronValue {
        var hashmap = MyronHashmap()
        for (key, value) in pairs { hashmap = hashmap.put(key: key, value: value) }
        return .hashmap(hashmap)
    }

    private var entries: [(MyronValue, MyronValue)] { [
        (.string("a"), .integer(1)),
        (.string("b"), .double(2.5)),
        (.string("c"), .list([.integer(1), .string("x")])),
        (.integer(4), .boolean(true)),
        (.double(5.5), .nothing),
        (.boolean(false), .symbol("s"))
    ] }

    // MARK: The Contract

    @Test("equal values hash equally")
    func equalValuesHashEqually() {
        let pairs: [(String, MyronValue, MyronValue)] = [
            ("integers", .integer(7), .integer(7)),
            ("doubles", .double(2.5), .double(2.5)),
            ("signed zero", .double(0.0), .double(-0.0)),
            ("strings", .string("abc"), .string("abc")),
            ("symbols", .symbol("abc"), .symbol("abc")),
            ("booleans", .boolean(true), .boolean(true)),
            ("nothing", .nothing, .nothing),
            ("lists", .list([.integer(1), .string("a")]), .list([.integer(1), .string("a")])),
            ("nested lists", .list([.list([.double(0.0)])]), .list([.list([.double(-0.0)])])),
            ("hashmaps", hashmap(entries), hashmap(entries.reversed())),
            ("nested hashmaps", .list([hashmap(entries)]), .list([hashmap(entries.reversed())]))
        ]

        for (label, fst, snd) in pairs {
            #expect(fst == snd, "\(label) should be equal")
            #expect(fst.hashValue == snd.hashValue, "\(label) are equal but hash differently")
        }
    }

    /// A hashmap holds its entries in whatever order the dictionary gives, so
    /// its hash must not depend on that order.
    @Test("a hashmap hashes the same however it was built")
    func hashmapOrderIndependence() {
        let reference = hashmap(entries)
        var hashes = Set<Int>([reference.hashValue])

        for _ in 0 ..< 16 {
            let shuffled = hashmap(entries.shuffled())
            #expect(shuffled == reference)
            hashes.insert(shuffled.hashValue)
        }

        #expect(hashes.count == 1, "one hashmap hashed \(hashes.count) different ways")
    }

    // MARK: Collections

    @Test("a set holds one of each equal value")
    func setDeduplicates() {
        var set = Set<MyronValue>()
        for _ in 0 ..< 8 { set.insert(hashmap(entries.shuffled())) }
        #expect(set.count == 1)

        set.insert(.integer(1))
        set.insert(.integer(1))
        set.insert(.string("x"))
        #expect(set.count == 3)
    }

    @Test("a dictionary finds what it stored")
    func dictionaryLookup() {
        var byValue = [MyronValue: String]()
        byValue[hashmap(entries)] = "stored"

        for _ in 0 ..< 8 {
            #expect(byValue[hashmap(entries.shuffled())] == "stored")
        }
    }

    // MARK: Callables

    private func primitive(_ name: String) -> MyronValue {
        return .primitive(MyronPrimitive(primitiveName: name, representations: []) { _, _ in
            return .nothing
        })
    }

    @Test("a callable that compares equal hashes equally")
    func callablesHashEqually() {
        let pairs: [(String, MyronValue, MyronValue)] = [
            ("primitives", primitive("a.p"), primitive("a.p")),
            ("higher order", .higherOrder(.map), .higherOrder(.map)),
            ("higher probe", .higherProbe(.all), .higherProbe(.all)),
            ("defines", .define("x"), .define("x")),
            ("nested", .list([primitive("a.p")]), .list([primitive("a.p")]))
        ]

        for (label, fst, snd) in pairs {
            #expect(fst == snd, "\(label) should be equal")
            #expect(fst.hashValue == snd.hashValue, "\(label) are equal but hash differently")
        }
    }

    @Test("a procedure compares and hashes by identity")
    func procedureIdentity() {
        let session = MyronSession()
        _ = session.eval("(define (f x) x)")
        _ = session.eval("(define (g x) x)")

        guard
            case .success(let f) = session.eval("f"),
            case .success(let g) = session.eval("g")
        else {
            Issue.record("could not read the procedures back")
            return
        }

        #expect(f == f)
        #expect(f.hashValue == f.hashValue)
        #expect(f != g)
        #expect(Set([f, g, f]).count == 2)
    }

    @Test("a set holds callables alongside data")
    func setOfCallables() {
        var set = Set<MyronValue>()
        set.insert(primitive("a.p"))
        set.insert(primitive("a.p"))
        set.insert(primitive("b.p"))
        set.insert(.higherOrder(.map))
        set.insert(.higherOrder(.map))
        set.insert(.higherOrder(.filter))
        set.insert(.integer(1))

        #expect(set.count == 5)
        #expect(set.contains(primitive("a.p")))
        #expect(set.contains(.higherOrder(.map)))
    }

    // MARK: Distinctness

    @Test("values that differ do not collapse")
    func distinctValuesStayDistinct() {
        let values: [MyronValue] = [
            .integer(1), .double(1.0), .string("1"), .symbol("1"), .boolean(true),
            .nothing, .list([]), .list([.integer(1)]), hashmap([]),
            hashmap([(.string("a"), .integer(1))])
        ]

        #expect(Set(values).count == values.count)
    }

}
