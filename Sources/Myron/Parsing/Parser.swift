import Foundation

// MARK: - Parser

final class Parser {
    let tokens: [Token]
    init(tokens: [Token]) { self.tokens = tokens }
    func parse() -> ([Expression], [MyronError]) { ParsingWorker(tokens: tokens).parse() }
}

// MARK: - Parsing Worker

final private class ParsingWorker {
    let tokens: [Token]
    var forms = [Expression]()
    var errors = [MyronError]()
    var cursor = 0
    
    init(tokens: [Token]) { self.tokens = tokens }
    
    func parse() -> ([Expression], [MyronError]) {
        while cursor < tokens.count {
            if let expression = parseExpression() { forms.append(expression) }
        }
        
        return (forms, errors)
    }
    
    enum ParsingShape {
        case expression, list, tick, quasiquote, unquote, unquoteSplicing

        var prefix: String? {
            switch self {
            case .tick: return "quote"
            case .quasiquote: return "quasiquote"
            case .unquote: return "unquote"
            case .unquoteSplicing: return "unquote-splicing"
            default: return nil
            }
        }

        var isPrefix: Bool { prefix != nil }
        var isExpression: Bool { self == .expression }
        var isList: Bool { self == .list }
        var isTick: Bool { self == .tick }
    }
    
    typealias ParsingWork = (ParsingShape, MyronLocation, [Expression])
    
    func parseExpression() -> Expression? {
        var work = [ParsingWork]()
        var build = [Expression]()
        var shape = ParsingShape.expression
        guard cursor < tokens.count else { return nil }
        var start = tokens[cursor].location
        
        func error(_ reason: MyronError.Reason, _ location: MyronLocation? = nil) {
            let resolved = location
            ?? (cursor < tokens.count ? tokens[cursor].location : tokens.last?.location)
            let error = MyronError(reason, at: resolved)
            errors.append(error)
        }

        func prefixError(for shape: ParsingShape, _ location: MyronLocation? = nil) {
            switch shape {
            case .quasiquote: error(.expectedExpressionAfterQuasiquote, location)
            case .tick: error(.expectedExpressionAfterTick, location)
            case .unquote, .unquoteSplicing: error(.expectedExpressionAfterUnquoting, location)
            default: error(.internal("not a prefix error when parsing expr"), location)
            }
        }

        while cursor < tokens.count {
            let token = tokens[cursor]
            defer { cursor += 1 }
            
            func pushWork(nextShape: ParsingShape) {
                work.append((shape, start, build))
                (shape, start, build) = (nextShape, token.location, [])
            }
            
            func popWork() -> Bool {
                guard let continuation = work.popLast() else { return false }
                (shape, start, build) = continuation
                return true
            }
            
            func atomMeta(_ location: MyronLocation? = nil) -> Expression.Metadata {
                return Expression.Metadata(location: location ?? token.location)
            }
            
            func listMeta(from start: MyronLocation) -> Expression.Metadata {
                return Expression.Metadata(location: start.lowerBound..<token.location.upperBound)
            }
            
            var production: Expression
            
            switch token.kind {
            case .leftBracket: pushWork(nextShape: .list); continue
            case .tick: pushWork(nextShape: .tick); continue
            case .quasiquote: pushWork(nextShape: .quasiquote); continue
            case .comma: pushWork(nextShape: .unquote); continue
            case .commaAt: pushWork(nextShape: .unquoteSplicing); continue
            case .boolean(let value): production = Expression.atom(.boolean(value), atomMeta())
            case .double(let value):  production = Expression.atom(.double(value), atomMeta())
            case .integer(let value): production = Expression.atom(.integer(value), atomMeta())
            case .nothing: production = Expression.atom(.nothing, atomMeta())
            case .string(let value):  production = Expression.atom(.string(value), atomMeta())
            case .symbol(let value):  production = Expression.atom(.symbol(value), atomMeta())
            case .rightBracket:
                guard !shape.isPrefix else { prefixError(for: shape); return nil }
                production = .list(build, listMeta(from: start))
                guard popWork() else { error(.unmatchedParenthesis, start); return nil }
            }
            
            switch shape {
            case .expression: return production
            case .list: build.append(production)
            case .tick, .quasiquote, .unquote, .unquoteSplicing:
                while let head = shape.prefix {
                    let symbol = Expression.atom(.symbol(head), atomMeta(start))
                    production = Expression.list([symbol, production], listMeta(from: start))
                    guard popWork() else {
                        error(.internal("empty stack after prefix")); return nil
                    }
                }
                if shape.isExpression { return production }
                build.append(production)
            }
        }
        
        switch shape {
        case .expression: error(.internal("parser did not return an expression"))
        case .list: error(.unmatchedParenthesis, start)
        case .tick, .quasiquote, .unquote, .unquoteSplicing: prefixError(for: shape)
        }
        
        return nil
    }

}
