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

// MARK: - Description

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
