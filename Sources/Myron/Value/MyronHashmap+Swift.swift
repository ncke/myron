import Foundation

// MARK: - Hashmap Dictionary Interoperability

extension MyronHashmap {

    public init(_ dictionary: Dictionary<MyronValue, MyronValue>) {
        var contents = [MyronValue: MyronValue]()
        for (key, value) in dictionary {
            if case .nothing = value { continue }
            guard key.isStorableKey else { continue }
            contents[key] = value
        }

        self.init(contents: contents)
    }

    public init<K, V>(_ dictionary: Dictionary<K, V>)
    where K: MyronValueRepresentable, V: MyronValueRepresentable
    {
        let convert: (K, V) -> (MyronValue, MyronValue)? = { dkey, dvalue in
            let mkey = dkey.myronValue
            let mval = dvalue.myronValue

            if case .nothing = mval { return nil }
            guard mkey.isStorableKey else { return nil }
            return (mkey, mval)
        }

        let pairs: [(MyronValue, MyronValue)] = dictionary.compactMap {
            (dkey, dvalue) in convert(dkey, dvalue)
        }

        let contents = Dictionary(pairs, uniquingKeysWith: { (first, _) in first })
        self.init(contents: contents)
    }

}

// MARK: - Hashmap Literal Expressibility

extension MyronHashmap: ExpressibleByDictionaryLiteral {

    public init(
        dictionaryLiteral elements: (any MyronValueRepresentable, any MyronValueRepresentable)...
    ) {
        self.init(withLiteralElements: elements)
    }

    init(
        withLiteralElements elements: [(any MyronValueRepresentable, any MyronValueRepresentable)]
    ) {
        var pairs = [(MyronValue, MyronValue)]()

        for (key, value) in elements {
            let mkey = key.myronValue
            let mvalue = value.myronValue

            guard mkey.isStorableKey else { continue }
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
        public typealias Element = (key: MyronValue, value: MyronValue)
        private let pairs: [Element]
        private var index = 0

        init(pairs: [Element]) {
            self.pairs = pairs
        }

        public mutating func next() -> (key: MyronValue, value: MyronValue)? {
            guard index < pairs.count else { return nil }
            let it = pairs[index]
            index += 1
            return it
        }
    }

}
