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

        switch head {

        case .primitive(let primitiveFunction):
            let result = primitiveFunction(tail)

            if let errorReason = result.second() {
                throw MyronError(
                    reason: errorReason,
                    location: expression.getLocation())
            }

            if let value = result.first() {
                return value
            }

            throw MyronError(
                reason: .internalError,
                location: expression.getLocation())

        case .procedure(let procedure):
            return try procedure(tail)

        default:
            throw MyronError(
                reason: .expectedFunction(head.typeName),
                location: expression.getLocation())
        }
    }

}
