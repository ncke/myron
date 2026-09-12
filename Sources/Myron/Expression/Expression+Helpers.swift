import Foundation

// MARK: - Expression Helpers

// MARK: - Expression Unwrapping

extension Expression {

    func unwrapList() throws -> ([Expression], Metadata) {
        guard case let .list(subexpressions, metadata) = self else {
            let reason = MyronError.Reason.unexpectedType(self.asValueKind(), [.list])
            throw MyronError(reason, at: self.location)
        }

        return (subexpressions, metadata)
    }

    func unwrapSymbolName() throws -> String {
        guard let name = self.asSymbolName() else {
            let reason = MyronError.Reason.unexpectedType(self.asValueKind(), [.symbol])
            throw MyronError(reason, at: self.location)
        }

        return name
    }

    func unwrapBinding() throws -> (String, Expression) {
        guard case let .list(subexprs, _) = self else {
            let reason = MyronError.Reason.unexpectedType(self.asValueKind(), [.list])
            throw MyronError(reason, at: self.location)
        }

        guard subexprs.count == 2 else {
            let reason = MyronError.Reason.unexpectedArity(subexprs.count, .exactly(2))
            throw MyronError(reason, at: self.location)
        }

        let name = try subexprs[subexprs.startIndex].unwrapSymbolName()
        let expr = subexprs[subexprs.startIndex + 1]

        return (name, expr)
    }

}

// MARK: - Expression Probing

extension Expression {

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

}

// MARK: - Value Kind Conversion

extension Expression {

    func asValueKind() -> MyronValue.Kind {
        switch self {
        case let .atom(atom, _): return atom.asValueKind()
        case .list: return .list
        }
    }

}

// MARK: - List Destructuring

extension Expression {

    func headtail() throws -> (Expression, ArraySlice<Expression>) {
        let (list, meta) = try self.unwrapList()
        return try list.headtail(meta.location)
    }

}
