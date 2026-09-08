import Foundation

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

    func headtail() throws -> (Expression, ArraySlice<Expression>) {
        let (list, meta) = try self.unwrapList()
        return try list.headtail(meta.location)
    }

}

// MARK: - Expression Collections

extension Collection where Element == Expression {

    func mustHaveAtLeast(_ n: Int, _ location: Location?) throws {
        if count < n {
            let reason = MyronError.Reason.unexpectedArity(count, .atLeast(n))
            throw MyronError(reason, at: location)
        }
    }

    func mustHaveExactly(_ n: Int, _ location: Location?) throws {
        if count != n {
            let reason = MyronError.Reason.unexpectedArity(count, .exactly(n))
            throw MyronError(reason, at: location)
        }
    }

    func headtail(_ location: Location?) throws -> (Element, Self.SubSequence) {
        try mustHaveAtLeast(1, location)
        let head = self[startIndex]
        let tail = self[index(after: startIndex)...]
        return (head, tail)

    }

}
