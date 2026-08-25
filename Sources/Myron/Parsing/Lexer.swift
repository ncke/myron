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
    let location: Range<Int>
}

// MARK: - Lexer

final class Lexer {
    let input: String
    let sourceHandle: Int?

    init(input: String, sourceHandle: Int?) {
        self.input = input
        self.sourceHandle = sourceHandle
    }

}

// MARK: - Tokenization

extension Lexer {

    func tokenize() -> ([Token], [MyronError]) {
        var cursor = input.startIndex
        var tokens: [Token] = []
        var errors: [MyronError] = []

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
            let isTick = character.isTick

            if isBracket || isSigning || isTick {
                let progress = input.index(after: cursor)
                emit(start: cursor, finish: progress)
                cursor = progress
                continue
            }

            let isWhitespace = character.isWhitespace
            let (progress, error) = isWhitespace
            ? scanUntil(
                from: cursor,
                ignoreQuotedContent: false) { ch in !ch.isWhitespace }
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
    ) -> Result<Token, MyronError> {
        precondition(start < finish)
        let text = String(input[start..<finish])
        let startOffset = input.distance(from: input.startIndex, to: start)
        let finishOffset = input.distance(from: input.startIndex, to: finish)
        let location = startOffset..<finishOffset

        func error(_ reason: MyronError.Reason) -> MyronError { MyronError(reason, at: location) }

        func token(_ kind: Token.Kind) -> Token {
            Token(kind: kind, sourceHandle: sourceHandle, location: location)
        }

        switch text {
        case Self.trueExpression: return .success(token(.boolean(true)))
        case Self.falseExpression: return .success(token(.boolean(false)))
        case Self.leftBracket: return .success(token(.leftBracket))
        case Self.rightBracket: return .success(token(.rightBracket))
        case Self.tick: return .success(token(.tick))
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
        ignoreQuotedContent: Bool = true,
        stopWhere stoppingCondition: (Character) -> Bool
    ) -> (String.Index, MyronError?) {
        var insideQuote = false
        var cursor = index

        while cursor < input.endIndex {
            defer { cursor = input.index(after: cursor) }
            let character = input[cursor]

            if ignoreQuotedContent {
                if character.isQuotation { insideQuote.toggle(); continue }
                if insideQuote { continue }
            }

            if stoppingCondition(character) { return (cursor, nil) }
        }

        if insideQuote {
            let errorStart = input.distance(from: input.startIndex, to: index)
            let errorFinish = input.distance(from: input.startIndex, to: cursor)
            let error = MyronError(.expectedQuote, at: errorStart..<errorFinish)
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
    private static let tick = "'"
}

// MARK: - Character Helper

fileprivate extension Character {
    var isBracket: Bool { self == "(" || self == ")" }
    var isDigit: Bool { ("0"..."9").contains(self) }
    var isQuotation: Bool { self == "\"" }
    var isSign: Bool { self == "+" || self == "-" }
    var isTick: Bool { self == "'" }
}
