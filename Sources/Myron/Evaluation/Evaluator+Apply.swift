import Foundation

// MARK: - Apply

extension Evaluator {

    static func apply(
        _ callable: Value,
        to arguments: [Value],
        in context: EvaluationContext,
        at location: Range<Int>?
    ) throws -> Value {
        switch callable {

        case .primitive(let primitiveFunction):
            let applier: (Value, [Value], Range<Int>?) throws -> Value = {
                callable, arguments, location in
                try Self.apply(callable, to: arguments, in: context, at: location)
            }

            let result = try primitiveFunction(arguments, applier, location)
            return result

        case .procedure(let procedure):
            return try procedure(arguments, context)

        default:
            throw MyronError(.expectedFunction(callable.kind), at: location)
        }
    }

}
