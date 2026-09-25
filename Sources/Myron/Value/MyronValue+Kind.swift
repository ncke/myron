import Foundation

// MARK: - Kind

extension MyronValue {

    public var kind: Kind {
        switch self {
        case .boolean: return .boolean
        case .define: return .define
        case .double: return .double
        case .hashmap: return .hashmap
        case .higherOrder: return .higherOrder
        case .higherProbe: return .higherProbe
        case .integer: return .integer
        case .list: return .list
        case .nothing: return .nothing
        case .primitive: return .primitive
        case .procedure: return .procedure
        case .record: return .record
        case .recordType: return .recordType
        case .set: return .set
        case .string: return .string
        case .symbol: return .symbol
        }
    }

}

// MARK: - MyronValue.Kind

extension MyronValue {

    public enum Kind: Equatable, Hashable, Sendable {
        case boolean
        case define
        case double
        case hashmap
        case higherOrder
        case higherProbe
        case integer
        case list
        case nothing
        case primitive
        case procedure
        case record
        case recordType
        case set
        case string
        case symbol
    }

}

// MARK: - Description

extension MyronValue.Kind: CustomStringConvertible {

    public var description: String {
        switch self {
        case .boolean: return "boolean"
        case .define: return "define"
        case .double: return "double"
        case .hashmap: return "hashmap"
        case .higherOrder: return "primitive"
        case .higherProbe: return "primitive"
        case .integer: return "integer"
        case .list: return "list"
        case .nothing: return "nothing"
        case .primitive: return "primitive"
        case .procedure: return "procedure"
        case .record: return "record"
        case .recordType: return "record-type"
        case .set: return "set"
        case .string: return "string"
        case .symbol: return "symbol"
        }
    }

}
