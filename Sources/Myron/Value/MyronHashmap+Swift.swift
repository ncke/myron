import Foundation

// MARK: - Hashmap Dictionary Interoperability

extension MyronHashmap {

    public init(_ dictionary: Dictionary<MyronKey, MyronValue>) throws {
        for (key, value) in dictionary {
            if case .nothing = value { throw MyronError(.dictionaryValueCannotBeNothing) }
            if case .double(let d) = key, !d.isFinite {
                throw MyronError(.invalidKey(key.value.kind))
            }
        }

        self.init(contents: dictionary)
    }

    public init<K, V>(_ dictionary: Dictionary<K, V>) throws
    where K: MyronKeyRepresentable, V: MyronValueRepresentable
    {
        let convert: (K, V) throws -> (MyronKey, MyronValue)? = { dkey, dvalue in
            let mkey = dkey.myronKey
            let mval = dvalue.myronValue

            if case .nothing = mval { return nil }

            if case .double(let d) = mkey, !d.isFinite {
                throw MyronError(.invalidKey(mkey.value.kind))
            }

            return (mkey, mval)
        }

        let pairs: [(MyronKey, MyronValue)] = try dictionary.compactMap {
            (dkey, dvalue) in try convert(dkey, dvalue)
        }

        let contents = Dictionary(pairs, uniquingKeysWith: { (first, _) in first })
        self.init(contents: contents)
    }

}

// MARK: - Hashmap Literal Expressibility

extension MyronHashmap: ExpressibleByDictionaryLiteral {

    public init(
        dictionaryLiteral elements: (any MyronKeyRepresentable, any MyronValueRepresentable)...
    ) {
        self.init(withLiteralElements: elements)
    }

    init(
        withLiteralElements elements: [(any MyronKeyRepresentable, any MyronValueRepresentable)]
    ) {
        var pairs = [(MyronKey, MyronValue)]()

        for (key, value) in elements {
            let mkey = key.myronKey
            let mvalue = value.myronValue

            if case .double(let d) = mkey, !d.isFinite {
                preconditionFailure("Myron hashmap literal has a non-finite key: \(mkey)")
            }

            if case .nothing = mvalue { continue }

            pairs.append((mkey, mvalue))
        }

        let contents = Dictionary(pairs, uniquingKeysWith: { (first, _) in first })
        self.init(contents: contents)
    }

}

// MARK: - Hashmap Sequence

extension MyronHashmap: Sequence {

    public func makeIterator() -> MyronHashmap.Iterator {
        return MyronHashmap.Iterator(pairs: pairs)
    }

    public struct Iterator: IteratorProtocol {
        public typealias Element = (key: MyronKey, value: MyronValue)
        private let pairs: [Element]
        private var index = 0

        init(pairs: [Element]) {
            self.pairs = pairs
        }

        public mutating func next() -> (key: MyronKey, value: MyronValue)? {
            guard index < pairs.count else { return nil }
            let it = pairs[index]
            index += 1
            return it
        }
    }

}
