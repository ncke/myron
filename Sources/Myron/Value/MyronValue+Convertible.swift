import Foundation

// MARK: - Myron Value Convertible

public protocol MyronValueConvertible {
    init(myronValue: MyronValue) throws
}

extension MyronValue: MyronValueConvertible {
    public init(myronValue: MyronValue) throws { self = myronValue }
}

extension MyronSet: MyronValueConvertible {
    public init(myronValue: MyronValue) throws {
        self = MyronSet(array: try myronValue.unwrapElements(nil))
    }
}

extension MyronHashmap: MyronValueConvertible {
    public init(myronValue: MyronValue) throws { self = try myronValue.unwrapHashmap(nil) }
}

extension Bool: MyronValueConvertible {
    public init(myronValue: MyronValue) throws { self = try myronValue.unwrapBoolean(nil) }
}

extension Int: MyronValueConvertible {
    public init(myronValue: MyronValue) throws { self = try myronValue.unwrapInteger(nil) }
}

extension Double: MyronValueConvertible {
    public init(myronValue: MyronValue) throws { self = try myronValue.unwrapDouble(nil) }
}

extension String: MyronValueConvertible {
    public init(myronValue: MyronValue) throws { self = try myronValue.unwrapString(nil) }
}

extension Array: MyronValueConvertible where Element: MyronValueConvertible {
    public init(myronValue: MyronValue) throws {
        self = try myronValue.unwrapElements(nil).map { try Element(myronValue: $0) }
    }
}

extension Optional: MyronValueConvertible where Wrapped: MyronValueConvertible {
    public init(myronValue: MyronValue) throws {
        if case .nothing = myronValue { self = .none; return }
        self = .some(try Wrapped(myronValue: myronValue))
    }
}

extension Set: MyronValueConvertible where Element: MyronValueConvertible {
    public init(myronValue: MyronValue) throws {
        self = Set(try myronValue.unwrapElements(nil).map { try Element(myronValue: $0) })
    }
}

extension Dictionary: MyronValueConvertible
where Key: MyronValueConvertible, Value: MyronValueConvertible
{
    public init(myronValue: MyronValue) throws {
        let pairs = try myronValue
            .unwrapHashmap(nil)
            .pairs
            .map { (k, v) in (try Key(myronValue: k), try Value(myronValue: v)) }
        self = Dictionary(pairs, uniquingKeysWith: { (first, _) in first })
    }
}

extension MyronValue {
    public func require<T: MyronValueConvertible>() throws -> T { try T(myronValue: self) }
}

extension MyronValue {
    public func requireBoolean() throws -> Bool { try self.unwrapBoolean(nil) }
    public func requireInteger() throws -> Int { try self.unwrapInteger(nil) }
    public func requireDouble() throws -> Double { try self.unwrapDouble(nil) }
    public func requireString() throws -> String { try self.unwrapString(nil) }
    public func requireSymbol() throws -> String { try self.unwrapSymbol(nil) }
}

// MARK: - MyronValueRepresentable

public protocol MyronValueRepresentable {
    var myronValue: MyronValue { get }
}

extension MyronValue: MyronValueRepresentable  { public var myronValue: MyronValue { return self } }

extension MyronSet: MyronValueRepresentable {
    public var myronValue: MyronValue { return .set(self) }
}

extension MyronHashmap: MyronValueRepresentable {
    public var myronValue: MyronValue { return .hashmap(self) }
}

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

extension Set: MyronValueRepresentable where Element: MyronValueRepresentable {
    public var myronValue: MyronValue {
        let myronElements = self.map { element in element.myronValue }
        return .set(MyronSet(array: myronElements))
    }
}

extension Dictionary: MyronValueRepresentable where
    Dictionary.Key: MyronValueRepresentable,
    Dictionary.Value: MyronValueRepresentable
{

    public var myronValue: MyronValue {
        let convert: (Dictionary.Key, Dictionary.Value) -> (MyronValue, MyronValue)? = {
            dk, dv in
            let mk = dk.myronValue
            let mv = dv.myronValue
            if case .nothing = mv { return nil }
            guard mk.isStorableKey else { return nil }
            return (mk, mv)
        }

        let pairs: [(MyronValue, MyronValue)] = self.compactMap { k, v in convert(k, v) }
        let contents = Dictionary<MyronValue, MyronValue>(
            pairs,
            uniquingKeysWith: { (first, _) in first })

        return .hashmap(MyronHashmap(contents: contents))
    }

}
