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
            let result = try primitiveFunction(arguments, Self.apply, location)
            return result

        case .procedure(let procedure):
            return try procedure(arguments)

        default:
            throw MyronError(.expectedFunction(callable.kind), at: location)
        }
    }

}
