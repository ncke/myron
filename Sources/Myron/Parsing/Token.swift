import Foundation

// MARK: - Token

struct Token {

    enum Kind: Equatable {
        case symbol(String)
        case integer(Int)
        case double(Double)
        case string(String)
        case boolean(Bool)
        case leftBracket
        case rightBracket
        case tick
    }

    let kind: Kind
    let sourceHandle: Int?
    let location: MyronLocation
}
