import Foundation

extension MyronValue {

    func asExpression(_ location: MyronLocation?) throws -> Expression {
        let exprMeta = Expression.Metadata(location: location)
        if let expr = MyronValue.makeExpression(from: self, meta: exprMeta) {
            return expr
        }

        var stack = [([Expression], ArraySlice<MyronValue>)]()
        var remaining: ArraySlice<MyronValue> = [self]
        var done = [Expression]()

        while true {
            if let next = remaining.first {
                remaining = remaining.dropFirst()
                if let elements = next.asList {
                    stack.append( (done, remaining) )
                    done = []
                    remaining = elements[...]
                    continue
                }

                guard let expr = MyronValue.makeExpression(from: next, meta: exprMeta) else {
                    throw MyronError(.valueIsNotCode(next.kind), at: location)
                        .withHint(.onlyAtomsAndListsAreCode)
                }

                done.append(expr)
                continue
            }

            if let popped = stack.popLast() {
                let list = Expression.list(done, exprMeta)
                (done, remaining) = popped
                done.append(list)
                continue
            }

            guard let result = done.first else {
                let explain = "`asExpression` completed with an empty stack"
                throw MyronError(.internal(explain), at: location)
            }

            return result
        }
    }

    private static func makeExpression(
        from value: MyronValue,
        meta: Expression.Metadata
    ) -> Expression? {
        switch value {
        case .boolean(let b): return .atom(.boolean(b), meta)
        case .double(let d): return .atom(.double(d), meta)
        case .integer(let i): return .atom(.integer(i), meta)
        case .nothing: return .atom(.nothing, meta)
        case .string(let s): return .atom(.string(s), meta)
        case .symbol(let s): return .atom(.symbol(s), meta)
        default: return nil
        }
    }

}
