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
        let convert: (Dictionary.Key, Dictionary.Value) -> (MyronKey, MyronValue)? = {
            dk, dv in
            let mv = dv.myronValue
            if case .nothing = mv { return nil }
            return (dk.myronKey, mv)
        }

        let pairs: [(MyronKey, MyronValue)] = self.compactMap { k, v in convert(k, v) }
        let contents = Dictionary<MyronKey, MyronValue>(
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
    public typealias Key = any MyronKeyRepresentable
    public typealias Value = MyronValueRepresentable

    public init(dictionaryLiteral elements: (Key, any Value)...) {
        let hashmap = MyronHashmap(withLiteralElements: elements)
        self = .hashmap(hashmap)
    }

}
