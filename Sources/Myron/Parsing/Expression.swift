import Foundation

// MARK: - Expression

public typealias Location = Range<Int>

indirect enum Expression {
    case atom(Atom, Metadata)
    case list([Expression], Metadata)

    struct Metadata {
        let location: Location?
    }
}

extension Expression {

    func getLocation() -> Location? {
        switch self {
        case let .atom(_, metadata): return metadata.location
        case let .list(_, metadata): return metadata.location
        }
    }

}

extension Expression: CustomStringConvertible {

    var description: String {
        switch self {
        case let .atom(atom, _):
            return atom.description
        case let .list(expressions, _):
            let descriptions = expressions.map(\.description)
            return "(\(descriptions.joined(separator: " ")))"
        }
    }

}

// MARK: - Expression Helpers

extension Expression {

    func unwrapBinding() throws -> (String, Expression) {
        guard case let .list(subexprs, _) = self else {
            let reason = MyronError.Reason.unexpectedType(self.asValueKind(), [.list])
            throw MyronError(reason, at: self.getLocation())
        }

        guard subexprs.count == 2 else {
            let reason = MyronError.Reason.unexpectedArity(subexprs.count, .exactly(2))
            throw MyronError(reason, at: self.getLocation())
        }

        let name = try subexprs[subexprs.startIndex].unwrapSymbolName()
        let expr = subexprs[subexprs.startIndex + 1]

        return (name, expr)
    }

    func unwrapList() throws -> ([Expression], Metadata) {
        guard case let .list(subexpressions, metadata) = self else {
            let reason = MyronError.Reason.unexpectedType(self.asValueKind(), [.list])
            throw MyronError(reason, at: self.getLocation())
        }

        return (subexpressions, metadata)
    }

    func asValueKind() -> Value.Kind {
        switch self {
        case let .atom(atom, _): return atom.asValueKind()
        case .list: return .list
        }
    }

    func asList() -> [Expression]? {
        guard case let .list(subexprs, _) = self else { return nil }
        return subexprs
    }

    func asSymbolName() -> String? {
        guard
            case .atom(let atom, _) = self,
            case .symbol(let name) = atom
        else {
            return nil
        }

        return name
    }

    func unwrapSymbolName() throws -> String {
        guard let name = self.asSymbolName() else {
            let reason = MyronError.Reason.unexpectedType(self.asValueKind(), [.symbol])
            throw MyronError(reason, at: self.getLocation())
        }

        return name
    }

}

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

    func asValueKind() -> Value.Kind {
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
