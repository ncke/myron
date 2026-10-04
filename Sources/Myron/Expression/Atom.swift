import Foundation

// MARK: - Atom

enum Atom {
    case boolean(Bool)
    case double(Double)
    case integer(Int)
    case nothing
    case string(String)
    case symbol(String)
}

// MARK: - Helpers

extension Atom {

    var isSymbol: Bool {
        switch self {
        case .symbol: return true
        default: return false
        }
    }

    func asValueKind() -> MyronValue.Kind {
        switch self {
        case .boolean: return .boolean
        case .double: return .double
        case .integer: return .integer
        case .nothing: return .nothing
        case .string: return .string
        case .symbol: return .symbol
        }
    }

}

// MARK: - Equatable & Hashable

extension Atom: Equatable, Hashable {}

// MARK: - Description

extension Atom: CustomStringConvertible {

    var description: String {
        switch self {
        case let .boolean(boolean): return boolean.description
        case let .double(double): return double.description
        case let .integer(integer): return integer.description
        case .nothing: return "nothing"
        case let .string(string): return string
        case let .symbol(symbol): return symbol
        }
    }

}
