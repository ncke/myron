import Foundation

// MARK: - Expression

indirect enum Expression {
    case atom(Atom, Metadata)
    case list([Expression], Metadata)

    struct Metadata {
        let location: Location?
    }
}

// MARK: - Location

public typealias Location = Range<Int>

protocol Locatable {
    var location: Location? { get }
}

struct LocatedList<Element>: Locatable, Collection {
    typealias Index = Int
    let location: Location?
    let elements: [Element]
    var startIndex: Int { elements.startIndex }
    var endIndex: Int { elements.endIndex }

    init(location: Location?, elements: [Element]) {
        self.location = location
        self.elements = elements
    }

    func index(after i: Int) -> Int { i + 1 }

    subscript(position: Int) -> Element { get { elements[position] } }
}

typealias LocatedSlice<Element> = Slice<LocatedList<Element>>

extension Expression: Locatable {

    var location: Location? {
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
