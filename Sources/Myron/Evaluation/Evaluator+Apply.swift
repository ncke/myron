import Foundation

// MARK: - Apply

extension Evaluator {

    static func apply(
        _ callable: Value,
        to arguments: [Value],
        at location: Range<Int>?
    ) throws -> Value {
        switch callable {

        case .primitive(let primitiveFunction):
            let result = primitiveFunction(arguments)

            if let errorReason = result.second() {
                throw MyronError(
                    reason: errorReason,
                    location: location)
            }

            if let value = result.first() {
                return value
            }

            throw MyronError(
                reason: .internalError,
                location: location)

        case .procedure(let procedure):
            return try procedure(arguments)

        default:
            throw MyronError(
                reason: .expectedFunction(callable.typeName),
                location: location)
        }
    }

}
