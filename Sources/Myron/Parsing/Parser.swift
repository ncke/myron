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
        case expression, list, tick
        var isExpression: Bool { if self == .expression { return true } else { return false } }
        var isList: Bool { if self == .list { return true } else { return false } }
        var isTick: Bool { if self == .tick { return true } else { return false } }
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
            case .boolean(let value): production = Expression.atom(.boolean(value), atomMeta())
            case .double(let value):  production = Expression.atom(.double(value), atomMeta())
            case .integer(let value): production = Expression.atom(.integer(value), atomMeta())
            case .string(let value):  production = Expression.atom(.string(value), atomMeta())
            case .symbol(let value):  production = Expression.atom(.symbol(value), atomMeta())
            case .rightBracket:
                guard !shape.isTick else { error(.expectedExpressionAfterTick); return nil }
                production = .list(build, listMeta(from: start))
                guard popWork() else { error(.unmatchedParenthesis, start); return nil }
            }
            
            switch shape {
            case .expression: return production
            case .list: build.append(production)
            case .tick:
                while shape.isTick {
                    let quote = Expression.atom(.symbol("quote"), atomMeta(start))
                    production = Expression.list([quote, production], listMeta(from: start))
                    guard popWork() else { error(.internal("empty stack after tick")); return nil }
                }
                
                if shape.isExpression { return production }
                build.append(production)
            }
        }
        
        switch shape {
        case .expression: error(.internal("parser did not return an expression"))
        case .list: error(.unmatchedParenthesis, start)
        case .tick: error(.expectedExpressionAfterTick)
        }
        
        return nil
    }
    
}
