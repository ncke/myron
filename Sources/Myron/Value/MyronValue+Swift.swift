import Foundation

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
    public typealias Key = any MyronValueRepresentable
    public typealias Value = MyronValueRepresentable

    public init(dictionaryLiteral elements: (Key, any Value)...) {
        let hashmap = MyronHashmap(withLiteralElements: elements)
        self = .hashmap(hashmap)
    }

}
