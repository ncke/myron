import Foundation

// MARK: - Evaluation Context

public struct EvaluationContext {
    let recursionDepth: Int

    func deeper() -> EvaluationContext {
        EvaluationContext(recursionDepth: recursionDepth + 1)
    }
}

// MARK: - Evaluator

final class Evaluator {
    let maximumRecursionDepth: Int?

    init(maximumRecursionDepth: Int?) {
        self.maximumRecursionDepth = maximumRecursionDepth
    }

}

// MARK: - Eval

extension Evaluator {

    func eval(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        let context = EvaluationContext(recursionDepth: 0)
        return try eval(expression, environment: environment, context: context)
    }

    func eval(
        _ expression: Expression,
        environment: Environment,
        context: EvaluationContext,
        inQuoteMode: Bool = false
    ) throws -> Value {
        try checkRecursionDepth(in: context, at: expression.getLocation())

        if !inQuoteMode, isSpecialForm(expression) {
            return try evalSpecialForm(
                expression,
                environment: environment,
                context: context)
        }

        if case .atom(let atom, _) = expression {
            if !inQuoteMode, case .symbol(let name) = atom {
                guard let value = environment.lookup(name) else {
                    throw MyronError(.unrecognisedSymbol, at: expression.getLocation())
                }

                return value
            }

            return Value.makeValue(from: atom)
        }

        if case .list(_, _) = expression {
            return try evalList(
                expression,
                environment: environment,
                context: context,
                inQuoteMode: inQuoteMode
            )
        }

        throw MyronError(.unimplementedFeature, at: expression.getLocation())
    }

}

// MARK: - Recursion Depth

extension Evaluator {

    func checkRecursionDepth(
        in context: EvaluationContext,
        at location: @autoclosure () -> Range<Int>?
    ) throws {
        guard let maximum = maximumRecursionDepth else { return }

        if context.recursionDepth > maximum {
            throw MyronError(.reachedMaximumRecursionDepth, at: location())
        }
    }

}
