import Foundation

// MARK: - Procedure

public struct Procedure {
    let parameters: [String]
    let bodies: [Expression]
    let environment: Environment
}

// MARK: - Value

public typealias Primitive = ([Value], Applier, Location?) throws -> Value

public typealias Applier = (Value, [Value], Location?) throws -> Value

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

// MARK: - Atomic Type Helper

extension Value {

    var isAtomicType: Bool {
        switch self {
        case .boolean, .double, .integer, .string, .symbol: return true
        default: return false
        }
    }


    static func makeValue(from expression: Expression) -> Value {
        if case .atom(let atom, _) = expression {
            return makeValue(from: atom)
        }

        var stack = [([Value], ArraySlice<Expression>)]()
        var remaining: ArraySlice<Expression> = [expression]
        var done = [Value]()

        while true {
            if let next = remaining.first {
                remaining = remaining.dropFirst()

                switch next {

                case .atom(let atom, _):
                    let value = makeValue(from: atom)
                    done.append(value)

                case .list(let elements, _):
                    stack.append( (done, remaining) )
                    done = []
                    remaining = elements[0...]
                }

                continue
            }

            if let popped = stack.popLast() {
                let list = Value.list(done)
                (done, remaining) = popped
                done.append(list)
                continue
            }

            guard let result = done.first else { fatalError() }
            return result
        }
    }

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

// MARK: - Kind

extension Value {

    public enum Kind: Equatable, CustomStringConvertible, Sendable {
        case boolean
        case double
        case integer
        case list
        case nothing
        case string
        case symbol
        case primitive
        case procedure
        case define

        public var description: String {
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

    public var kind: Kind {
        switch self {
        case .boolean: return .boolean
        case .double: return .double
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
        case .string(let string): "\"\(string)\""
        case .symbol(let symbol): "\(symbol)"
        case .primitive: "<primitive>"
        case .procedure: "<procedure>"
        case .define(let name): "<define: \(name)>"
        }
    }

}
