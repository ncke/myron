import Foundation

// MARK: - Evaluate Lists

extension Evaluator {

    func evalList(
        _ expression: Expression,
        environment: Environment,
        inQuoteMode: Bool
    ) throws -> Value {
        guard case let .list(elements, _) = expression else {
            fatalError("evalList called with non-list expression")
        }

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
            throw MyronError(
                reason: .emptyApplication,
                location: expression.getLocation())
        }

        let tail = Array(values.dropFirst())
        let location = expression.getLocation()

        let result = try Evaluator.apply(head, to: tail, at: location)
        return result
    }

}
