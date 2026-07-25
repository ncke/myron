import Foundation

// MARK: - Token

struct Token {

    enum Kind {
        case symbol(String)
        case integer(Int)
        case double(Double)
        case string(String)
        case boolean(Bool)
        case leftBracket
        case rightBracket
    }

    let kind: Kind
    let location: Range<String.Index>
}

// MARK: - Lexer

final class Lexer {
    let input: String

    init(input: String) {
        self.input = input
    }

}

// MARK: - Tokenization

extension Lexer {

    func tokenize() -> ([Token], [CompilerError]) {
        var cursor = input.startIndex
        var tokens: [Token] = []
        var errors: [CompilerError] = []

        func emit(start: String.Index, finish: String.Index) {
            let outcome = makeToken(start: start, finish: finish)
            switch outcome {
            case .success(let token): tokens.append(token)
            case .failure(let error): errors.append(error)
            }
        }

        func isPeekDigit() -> Bool {
            let peek = input.index(after: cursor)
            return peek < input.endIndex && input[peek].isDigit
        }

        while cursor < input.endIndex {
            let character = input[cursor]

            let isBracket = character.isBracket
            let isSigning = character.isSign && !isPeekDigit()

            if isBracket || isSigning {
                let progress = input.index(after: cursor)
                emit(start: cursor, finish: progress)
                cursor = progress
                continue
            }

            let isWhitespace = character.isWhitespace
            let (progress, error) = isWhitespace
            ? scanUntil(from: cursor) { ch in !ch.isWhitespace }
            : scanUntil(from: cursor) { ch in ch.isWhitespace || ch.isBracket }

            if let error {
                errors.append(error)
            } else if !isWhitespace {
                emit(start: cursor, finish: progress)
            }

            cursor = progress
        }

        return (tokens, errors)
    }

}

// MARK: - Token Construction

private extension Lexer {

    func makeToken(
        start: String.Index,
        finish: String.Index
    ) -> Result<Token, CompilerError> {
        precondition(start < finish)
        let location = start..<finish
        let text = String(input[location])

        func error(_ reason: CompilerError.Reason) -> CompilerError {
            CompilerError(reason: reason, location: location)
        }

        func token(_ kind: Token.Kind) -> Token {
            Token(kind: kind, location: location)
        }

        switch text {
        case Self.trueExpression: return .success(token(.boolean(true)))
        case Self.falseExpression: return .success(token(.boolean(false)))
        case Self.leftBracket: return .success(token(.leftBracket))
        case Self.rightBracket: return .success(token(.rightBracket))
        default: break
        }

        let first = text[text.startIndex]
        let hasMultipleCharacters = text.count > 1

        if  hasMultipleCharacters,
            first.isQuotation,
            text[text.index(before: text.endIndex)].isQuotation
        {
            let string = String(text.dropFirst().dropLast())
            return .success(token(.string(string)))
        }

        let isNumberCandidate = first.isDigit
        let isSignedCandidate = first.isSign
        && hasMultipleCharacters
        && text[text.index(after: text.startIndex)].isDigit

        if !(isNumberCandidate || isSignedCandidate) {
            return .success(token(.symbol(text)))
        }

        let isDoubleCandidate = text.contains(Self.decimalPoint)
        if isDoubleCandidate {
            guard let double = Double(text) else {
                return .failure(error(.invalidNumber))
            }

            return .success(token(.double(double)))
        }

        guard let integer = Int(text) else {
            return .failure(error(.invalidNumber))
        }

        return .success(token(.integer(integer)))
    }

}

// MARK: - Scanning

private extension Lexer {

    func scanUntil(
        from index: String.Index,
        stopWhere stoppingCondition: (Character) -> Bool
    ) -> (String.Index, CompilerError?) {
        var insideQuote = false
        var cursor = index

        while cursor < input.endIndex {
            defer { cursor = input.index(after: cursor) }
            let character = input[cursor]

            if character.isQuotation { insideQuote.toggle(); continue }
            if insideQuote { continue }
            if stoppingCondition(character) { return (cursor, nil) }
        }

        if insideQuote {
            let error = CompilerError(
                reason: .expectedQuote,
                location: index..<cursor)
            return (cursor, error)
        }

        return (cursor, nil)
    }

}

// MARK: - Lexing Constants

private extension Lexer {
    private static let decimalPoint = "."
    private static let trueExpression = "true"
    private static let falseExpression = "false"
    private static let leftBracket = "("
    private static let rightBracket = ")"
}

// MARK: - Character Helper

fileprivate extension Character {
    var isBracket: Bool { self == "(" || self == ")" }
    var isDigit: Bool { ("0"..."9").contains(self) }
    var isQuotation: Bool { self == "\"" }
    var isSign: Bool { self == "+" || self == "-" }
}

