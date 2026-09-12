import Foundation

// MARK: - MyronValueRepresentable

public protocol MyronValueRepresentable {
    var myronValue: MyronValue { get }
}

extension MyronValue: MyronValueRepresentable  { public var myronValue: MyronValue { return self } }

extension Bool: MyronValueRepresentable   { public var myronValue: MyronValue { .boolean(self) } }

extension Double: MyronValueRepresentable { public var myronValue: MyronValue { .double(self) } }

extension Int: MyronValueRepresentable    { public var myronValue: MyronValue { .integer(self) } }

extension String: MyronValueRepresentable { public var myronValue: MyronValue { .string(self) } }

extension Optional: MyronValueRepresentable where Wrapped: MyronValueRepresentable {
    public var myronValue: MyronValue {
        switch self {
        case .some(let wrapped): return wrapped.myronValue
        case .none: return .nothing
        }
    }
}

extension Array: MyronValueRepresentable where Element: MyronValueRepresentable {
    public var myronValue: MyronValue {
        let myronElements = self.map { element in element.myronValue }
        return .list(myronElements)
    }
}

extension Dictionary: MyronValueRepresentable where
    Dictionary.Key: MyronKeyRepresentable,
    Dictionary.Value: MyronValueRepresentable
{

    public var myronValue: MyronValue {
        let convert: (Dictionary.Key, Dictionary.Value) -> (MyronValue.Key, MyronValue)? = {
            dk, dv in
            let mv = dv.myronValue
            if case .nothing = mv { return nil }
            return (dk.myronKey, mv)
        }

        let pairs: [(MyronValue.Key, MyronValue)] = self.compactMap { k, v in convert(k, v) }
        let contents = Dictionary<MyronValue.Key, MyronValue>(
            pairs,
            uniquingKeysWith: { (first, _) in first })

        return .hashmap(MyronHashmap(contents: contents))
    }

}

// MARK: - Value Expressibility

extension MyronValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) { self = .nothing }
}

extension MyronValue: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) { self = .boolean(value) }
}

extension MyronValue: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) { self = .integer(value) }
}

extension MyronValue: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension MyronValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) { self = .string(value) }
}

extension MyronValue: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = MyronValueRepresentable
    public init(arrayLiteral elements: any ArrayLiteralElement...) {
        let listElements = elements.map { element in element.myronValue }
        self = .list(listElements)
    }
}

extension MyronValue: ExpressibleByDictionaryLiteral {

    public typealias Value = MyronValueRepresentable

    public init(dictionaryLiteral elements: (Key, any Value)...) {
        let hashmap = MyronHashmap(elements: elements)
        self = .hashmap(hashmap)
    }

}

// MARK: - MyronKeyRepresentable

public protocol MyronKeyRepresentable: Hashable {
    var myronKey: MyronValue.Key { get }
}

extension Bool: MyronKeyRepresentable   { public var myronKey: MyronValue.Key { .boolean(self) } }

extension Int: MyronKeyRepresentable    { public var myronKey: MyronValue.Key { .integer(self) } }

extension String: MyronKeyRepresentable { public var myronKey: MyronValue.Key { .string(self) } }

extension MyronValue.Key: MyronKeyRepresentable { public var myronKey: MyronValue.Key { return self } }

// MARK: - Key Expressibility

extension MyronValue.Key: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) { self = .boolean(value) }
}

extension MyronValue.Key: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) { self = .integer(value) }
}

extension MyronValue.Key: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension MyronValue.Key: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) { self = .string(value) }
}

// MARK: - Hashmap Dictionary Interoperability

extension MyronHashmap {

    public init(_ dictionary: Dictionary<MyronValue.Key, MyronValue>) throws {
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
        let convert: (K, V) throws -> (MyronValue.Key, MyronValue)? = { dkey, dvalue in
            let mkey = dkey.myronKey
            let mval = dvalue.myronValue

            if case .nothing = mval { return nil }

            if case .double(let d) = mkey, !d.isFinite {
                throw MyronError(.invalidKey(mkey.value.kind))
            }

            return (mkey, mval)
        }

        let pairs: [(MyronValue.Key, MyronValue)] = try dictionary.compactMap {
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
        self.init(elements: elements)
    }

    fileprivate init(elements: [(any MyronKeyRepresentable, any MyronValueRepresentable)]) {
        var pairs = [(MyronValue.Key, MyronValue)]()

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
        public typealias Element = (key: MyronValue.Key, value: MyronValue)
        private let pairs: [Element]
        private var index = 0

        init(pairs: [Element]) {
            self.pairs = pairs
        }

        public mutating func next() -> (key: MyronValue.Key, value: MyronValue)? {
            guard index < pairs.count else { return nil }
            let it = pairs[index]
            index += 1
            return it
        }
    }

}
