import Foundation

// MARK: - Evaluate Lists

extension Evaluator {

    func evalList(
        _ expression: Expression,
        environment: Environment,
        inQuoteMode: Bool
    ) throws -> Value {
        let (elements, _) = try expression.unwrapList(#function)

        let values = try elements.map { element in
            let value = try eval(
                element,
                environment: environment,
                inQuoteMode: inQuoteMode)
            return value
        }

        if inQuoteMode {
            return .list(values)
        }

        guard let head = values.first else {
            throw MyronError(.emptyApplication, at: expression.getLocation())
        }

        let tail = Array(values.dropFirst())
        let location = expression.getLocation()

        let result = try Evaluator.apply(head, to: tail, at: location)
        return result
    }

}
