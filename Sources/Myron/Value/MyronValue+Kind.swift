import Foundation

// MARK: - Kind

extension MyronValue {

    public var kind: Kind {
        switch self {
        case .boolean: return .boolean
        case .double: return .double
        case .hashmap: return .hashmap
        case .higherOrder: return .higherOrder
        case .higherProbe: return .higherProbe
        case .integer: return .integer
        case .list: return .list
        case .nothing: return .nothing
        case .string: return .string
        case .symbol: return .symbol
        case .primitive: return .primitive
        case .procedure: return .procedure
        case .define: return .define
        }
    }

}

// MARK: - MyronValue.Kind

extension MyronValue {

    public enum Kind: Equatable, Sendable {
        case boolean
        case double
        case hashmap
        case higherOrder
        case higherProbe
        case integer
        case list
        case nothing
        case string
        case symbol
        case primitive
        case procedure
        case define
    }

}

// MARK: - Description

extension MyronValue.Kind: CustomStringConvertible {

    public var description: String {
        switch self {
        case .boolean: return "boolean"
        case .double: return "double"
        case .hashmap: return "hashmap"
        case .higherOrder: return "procedure"
        case .higherProbe: return "procedure"
        case .integer: return "integer"
        case .list: return "list"
        case .nothing: return "nothing"
        case .string: return "string"
        case .symbol: return "symbol"
        case .primitive: return "primitive"
        case .procedure: return "procedure"
        case .define: return "define"
        }
    }

}
