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

// MARK: - Flat

//extension Expression {
//    var flat: FlatSequence { FlatSequence(base: self) }
//    
//    struct FlatSequence: Sequence {
//        typealias Iterator = Expression.FlatIterator
//        let base: Expression
//        func makeIterator() -> Expression.FlatIterator { FlatIterator(value: base) }
//    }
//    
//    struct FlatIterator: IteratorProtocol {
//        typealias Element = Expression
//        private var work: [Expression]
//        
//        init(value: Expression) {
//            self.work = [value]
//        }
//        
//        mutating func next() -> Expression? {
//            guard let value = work.popLast() else { return nil }
//            if case .list(let elements, _) = value { work.append(contentsOf: elements) }
//            return value
//        }
//    }
//    
//}

//// MARK: - Hashable
//
//extension Expression: Equatable, Hashable {
//    
//    public static func == (lhs: Expression, rhs: Expression) -> Bool {
//        var work = [(lhs, rhs)]
//
//        while let (fst, snd) = work.popLast() {
//            switch (fst, snd) {
//                
//            case (.atom(let left, _), .atom(let right, _)):
//                guard left == right else { return false }
//                
//            case (.list(let left, _), .list(let right, _)):
//                guard left.count == right.count else { return false }
//                work.append(contentsOf: zip(left, right))
//                
//            default:
//                return false
//            }
//        }
//
//        return true
//    }
//    
//    public func hash(into hasher: inout Hasher) {
//        flat.forEach { expression in
//            switch expression {
//            case .atom(let atom, _):
//                atom.hash(into: &hasher)
//            case .list:
//                break
//            }
//        }
//    }
//    
//}
