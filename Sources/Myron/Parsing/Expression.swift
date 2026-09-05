import Foundation

// MARK: - Expression

indirect enum Expression {
    case atom(Atom, Metadata)
    case list([Expression], Metadata)

    struct Metadata {
        let location: Range<Int>?
    }
}

extension Expression {

    func getLocation() -> Range<Int>? {
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

    func unwrapList(_ function: String) throws -> ([Expression], Metadata) {
        guard case let .list(subexpressions, metadata) = self else {
            let message = "'\(function)' expected a list"
            throw MyronError(.internalError(message), at: getLocation())
        }

        return (subexpressions, metadata)
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
