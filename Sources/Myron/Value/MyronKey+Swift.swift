import Foundation

// MARK: - MyronKeyRepresentable

public protocol MyronKeyRepresentable: Hashable {
    var myronKey: MyronKey { get }
}

extension Bool: MyronKeyRepresentable   { public var myronKey: MyronKey { .boolean(self) } }

extension Int: MyronKeyRepresentable    { public var myronKey: MyronKey { .integer(self) } }

extension String: MyronKeyRepresentable { public var myronKey: MyronKey { .string(self) } }

extension MyronKey: MyronKeyRepresentable { public var myronKey: MyronKey { return self } }

// MARK: - Key Expressibility

extension MyronKey: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) { self = .boolean(value) }
}

extension MyronKey: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) { self = .integer(value) }
}

extension MyronKey: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension MyronKey: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) { self = .string(value) }
}


