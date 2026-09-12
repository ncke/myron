import Foundation

// MARK: - Atom

enum Atom {
    case symbol(String)
    case boolean(Bool)
    case integer(Int)
    case double(Double)
    case string(String)
}

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
        case .integer: return .integer
        case .double: return .double
        case .string: return .string
        case .symbol: return .symbol
        }
    }

}

extension Atom: CustomStringConvertible {

    var description: String {
        switch self {
        case let .symbol(symbol): return symbol
        case let .boolean(boolean): return boolean.description
        case let .integer(integer): return integer.description
        case let .double(double): return double.description
        case let .string(string): return string
        }
    }

}
