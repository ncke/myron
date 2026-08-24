import Foundation

// MARK: - Value

public typealias Primitive = ([Value]) -> Either<Value, MyronError.Reason>

public typealias Procedure = ([Value]) throws -> Value

public enum Value {
    case boolean(Bool)
    case double(Double)
    case integer(Int)
    case list([Value])
    case nothing
    case string(String)
    case symbol(String)
    case primitive(Primitive)
    case procedure(Procedure)
    case define(String)
}

extension Value {

    var isAtomicType: Bool {
        switch self {
        case .boolean, .double, .integer, .string, .symbol: return true
        default: return false
        }
    }

    var typeName: String {
        switch self {
        case .boolean: return "boolean"
        case .double: return "double"
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

extension Value {

    static func makeValue(from atom: Atom) -> Value {
        switch atom {
        case .boolean(let boolean): .boolean(boolean)
        case .double(let double): .double(double)
        case .integer(let integer): .integer(integer)
        case .string(let string): .string(string)
        case .symbol(let symbol): .symbol(symbol)
        }
    }

}

// MARK: - Description

extension Value: CustomStringConvertible {

    public var description: String {
        switch self {
        case .boolean(let boolean): "\(boolean)"
        case .double(let double): "\(double)"
        case .integer(let integer): "\(integer)"
        case .list(let list):
            "(" + list.map(\.description).joined(separator: " ") + ")"
        case .nothing: "<nothing>"
        case .string(let string): "\(string)"
        case .symbol(let symbol): "\(symbol)"
        case .primitive: "<primitive>"
        case .procedure: "<procedure>"
        case .define(let name): "<define: \(name)>"
        }
    }

}
