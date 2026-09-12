import Foundation

// MARK: - MyronValueRepresentable

public protocol MyronValueRepresentable {
    var myronValue: Value { get }
}

extension Value: MyronValueRepresentable  { public var myronValue: Value { return self } }

extension Bool: MyronValueRepresentable   { public var myronValue: Value { .boolean(self) } }

extension Double: MyronValueRepresentable { public var myronValue: Value { .double(self) } }

extension Int: MyronValueRepresentable    { public var myronValue: Value { .integer(self) } }

extension String: MyronValueRepresentable { public var myronValue: Value { .string(self) } }

extension Optional: MyronValueRepresentable where Wrapped: MyronValueRepresentable {
    public var myronValue: Value {
        switch self {
        case .some(let wrapped): return wrapped.myronValue
        case .none: return .nothing
        }
    }
}

extension Array: MyronValueRepresentable where Element: MyronValueRepresentable {
    public var myronValue: Value {
        let myronElements = self.map { element in element.myronValue }
        return .list(myronElements)
    }
}

extension Dictionary: MyronValueRepresentable where
    Dictionary.Key: MyronKeyRepresentable,
    Dictionary.Value: MyronValueRepresentable
{

    public var myronValue: Myron.Value {
        let convert: (Dictionary.Key, Dictionary.Value) -> (Myron.Value.Key, Myron.Value)? = {
            dk, dv in
            let mv = dv.myronValue
            if case .nothing = mv { return nil }
            return (dk.myronKey, mv)
        }

        let pairs: [(Myron.Value.Key, Myron.Value)] = self.compactMap { k, v in convert(k, v) }
        let contents = Dictionary<Myron.Value.Key, Myron.Value>(
            pairs,
            uniquingKeysWith: { (first, _) in first })

        return .hashmap(MyronHashmap(contents: contents))
    }

}

// MARK: - Value Expressibility

extension Value: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) { self = .nothing }
}

extension Value: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) { self = .boolean(value) }
}

extension Value: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) { self = .integer(value) }
}

extension Value: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension Value: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) { self = .string(value) }
}

extension Value: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = MyronValueRepresentable
    public init(arrayLiteral elements: any ArrayLiteralElement...) {
        let listElements = elements.map { element in element.myronValue }
        self = .list(listElements)
    }
}

// MARK: - MyronKeyRepresentable

public protocol MyronKeyRepresentable: Hashable {
    var myronKey: Value.Key { get }
}

extension Bool: MyronKeyRepresentable   { public var myronKey: Value.Key { .boolean(self) } }

extension Int: MyronKeyRepresentable    { public var myronKey: Value.Key { .integer(self) } }

extension String: MyronKeyRepresentable { public var myronKey: Value.Key { .string(self) } }

extension Value.Key: MyronKeyRepresentable { public var myronKey: Value.Key { return self } }

// MARK: - Key Expressibility

extension Value.Key: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) { self = .boolean(value) }
}

extension Value.Key: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) { self = .integer(value) }
}

extension Value.Key: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension Value.Key: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) { self = .string(value) }
}

// MARK: - Hashmap Dictionary Interoperability

extension MyronHashmap {

    public init(_ dictionary: Dictionary<Myron.Value.Key, Myron.Value>) throws {
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
        let convert: (K, V) throws -> (Myron.Value.Key, Myron.Value)? = { dkey, dvalue in
            let mkey = dkey.myronKey
            let mval = dvalue.myronValue

            if case .nothing = mval { return nil }

            if case .double(let d) = mkey, !d.isFinite {
                throw MyronError(.invalidKey(mkey.value.kind))
            }

            return (mkey, mval)
        }

        let pairs: [(Myron.Value.Key, Myron.Value)] = try dictionary.compactMap {
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
        var pairs = [(Myron.Value.Key, Myron.Value)]()

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
        public typealias Element = (key: Myron.Value.Key, value: Myron.Value)
        private let pairs: [Element]
        private var index = 0

        init(pairs: [Element]) {
            self.pairs = pairs
        }

        public mutating func next() -> (key: Myron.Value.Key, value: Myron.Value)? {
            guard index < pairs.count else { return nil }
            let it = pairs[index]
            index += 1
            return it
        }
    }

}
