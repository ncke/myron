import Foundation

// MARK: - Evaluator

final class Evaluator {

    func eval(
        _ expression: Expression,
        environment: Environment,
        inQuoteMode: Bool = false
    ) throws -> Value {
        if !inQuoteMode, isSpecialForm(expression) {
            return try evalSpecialForm(expression, environment: environment)
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
                inQuoteMode: inQuoteMode
            )
        }

        throw MyronError(.unimplementedFeature, at: expression.getLocation())
    }

}
