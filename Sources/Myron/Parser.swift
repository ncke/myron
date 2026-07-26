import Foundation

// MARK: - Parser

final class Parser {

    let tokens: [Token]

    init(tokens: [Token]) {
        self.tokens = tokens
    }

}

// MARK: - Parsing

extension Parser {

    func parse() -> ([Expression], [CompilerError]) {
        var forms = [Expression]()
        var errors = [CompilerError]()
        var cursor = 0

        while cursor < tokens.count {
            let (progress, expression) = parseExpression(
                from: cursor,
                errors: &errors)

            if let expression { forms.append(expression) }
            cursor = progress
        }

        return (forms, errors)
    }

    private func parseExpression(
        from startIndex: Int,
        errors: inout [CompilerError]
    ) -> (Int, Expression?) {
        let token = tokens[startIndex]

        func metadata() -> Expression.Metadata {
            Expression.Metadata(location: token.location)
        }

        switch token.kind {
        case .leftBracket:
            let (progress, result) = parseList(
                from: startIndex + 1,
                openingToken: token,
                errors: &errors)
            return (progress, result)
        case .rightBracket:
            let error = CompilerError(
                reason: .unmatchedParenthesis,
                location: token.location)
            errors.append(error)
            return (startIndex + 1, nil)
        case .boolean(let value):
            return (startIndex + 1, .atom(.boolean(value), metadata()))
        case .double(let value):
            return (startIndex + 1, .atom(.double(value), metadata()))
        case .integer(let value):
            return (startIndex + 1, .atom(.integer(value), metadata()))
        case .string(let string):
            return (startIndex + 1, .atom(.string(string), metadata()))
        case .symbol(let symbol):
            return (startIndex + 1, .atom(.symbol(symbol), metadata()))
        }
    }

    private func parseList(
        from startIndex: Int,
        openingToken: Token,
        errors: inout [CompilerError]
    ) -> (Int, Expression?) {
        var list = [Expression]()
        var token: Token?
        var cursor = startIndex

        while cursor < tokens.count {
            token = tokens[cursor]
            if token?.kind == .rightBracket { break }

            let (progress, expression) = parseExpression(
                from: cursor,
                errors: &errors)

            if let expression { list.append(expression) }
            cursor = progress
        }

        let openingLocation = openingToken.location
        let start = openingLocation.lowerBound
        let finish = token?.location.upperBound ?? openingLocation.upperBound
        let location = start..<finish

        if token?.kind != .rightBracket {
            let error = CompilerError(
                reason: .expectedRightBracket,
                location: location)
            errors.append(error)
        }

        let metadata = Expression.Metadata(location: location)
        let listExpression = Expression.list(list, metadata)
        return (cursor + 1, listExpression)
    }

}

// MARK: - Syntax Tree

indirect enum Expression {
    case atom(Atom, Metadata)
    case list([Expression], Metadata)

    struct Metadata {
        let location: Range<String.Index>
    }
}

enum Atom {
    case symbol(String)
    case boolean(Bool)
    case integer(Int)
    case double(Double)
    case string(String)
}
