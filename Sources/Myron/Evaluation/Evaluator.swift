import Foundation

// MARK: - Value

public typealias Primitive = ([Value]) -> Either<Value, MyronError.Reason>

public typealias Procedure = ([Value]) throws -> Value

public enum Value {
    case boolean(Bool)
    case double(Double)
    case integer(Int)
    case list([Value])
    case nothing
    case string(String)
    case symbol(String)
    case primitive(Primitive)
    case procedure(Procedure)
    case define(String)
}

extension Value {

    var isAtomicType: Bool {
        switch self {
        case .boolean, .double, .integer, .string, .symbol: return true
        default: return false
        }
    }

    var typeName: String {
        switch self {
        case .boolean: return "boolean"
        case .double: return "double"
        case .integer: return "integer"
        case .list: return "list"
        case .nothing: return "nothing"
        case .string: return "string"
        case .symbol: return "symbol"
        case .primitive: return "primitive"
        case .procedure: return "procedure"
        case .define: return "define"
        }
    }

}

extension Value {

    static func makeValue(from atom: Atom) -> Value {
        switch atom {
        case .boolean(let boolean): .boolean(boolean)
        case .double(let double): .double(double)
        case .integer(let integer): .integer(integer)
        case .string(let string): .string(string)
        case .symbol(let symbol): .symbol(symbol)
        }
    }

}

extension Value: CustomStringConvertible {

    public var description: String {
        switch self {
        case .boolean(let boolean): "\(boolean)"
        case .double(let double): "\(double)"
        case .integer(let integer): "\(integer)"
        case .list(let list):
            "(" + list.map(\.description).joined(separator: " ") + ")"
        case .nothing: "<nothing>"
        case .string(let string): "\(string)"
        case .symbol(let symbol): "\(symbol)"
        case .primitive: "<primitive>"
        case .procedure: "<procedure>"
        case .define(let name): "<define: \(name)>"
        }
    }

}

// MARK: - Evaluator

class Evaluator {

    private weak var registry: EnvironmentRegistry?

    init(registry: EnvironmentRegistry) {
        self.registry = registry
    }

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
                    throw MyronError(
                        reason: .unrecognisedSymbol,
                        location: expression.getLocation())
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

        throw MyronError(
            reason: .unimplementedFeature,
            location: expression.getLocation())
    }

}

// MARK: - Special Forms

private extension Evaluator {

    static let specialFormNames: Set<String> = [
        "if", "define", "quote"
    ]

    func getSpecialFormName(_ expression: Expression) -> String? {
        switch expression {
        case .list(let elements, _):
            if  case .atom(let atom, _) = elements.first,
                case .symbol(let name) = atom
            {
                return name
            }

            return nil

        default:
            return nil
        }
    }

    func isSpecialForm(_ expression: Expression) -> Bool {
        guard let name = getSpecialFormName(expression) else { return false }
        return Self.specialFormNames.contains(name)
    }

    func evalSpecialForm(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        func makeUnimplementedFeatureError() -> MyronError {
            MyronError(
                reason: .unimplementedFeature,
                location: expression.getLocation())
        }

        guard let name = getSpecialFormName(expression) else {
            throw makeUnimplementedFeatureError()
        }

        switch name {

        case "define":
            return try evalDefine(expression, environment: environment)

        case "if":
            return try evalIf(expression, environment: environment)

        case "quote":
            return try evalQuote(expression, environment: environment)

        default:
            throw makeUnimplementedFeatureError()
        }

    }

    func evalDefine(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        guard case let .list(elements, _) = expression else {
            fatalError("evalList called with non-list expression")
        }

        guard elements.count == 3 else {
            throw MyronError(
                reason: .unexpectedArity,
                location: expression.getLocation())
        }
        
        let nameExpression = elements[1]

        if case .atom(let atom, _) = nameExpression {
            guard case .symbol(let name) = atom else {
                throw MyronError(
                    reason: .typeMismatch,
                    location: expression.getLocation())
            }

            let value = try eval(elements[2], environment: environment)
            environment.insert(name, value: value)
            return .define(name)
        }

        if case .list(let parameters, _) = nameExpression {
            guard parameters.count > 0 else {
                throw MyronError(
                    reason: .unexpectedArity,
                    location: expression.getLocation())
            }

            guard
                case let .atom(atom, _) = parameters.first,
                case .symbol(let procedureName) = atom
            else {
                throw MyronError(
                    reason: .typeMismatch,
                    location: expression.getLocation())
            }

            let parameterNames = try parameters.dropFirst().map { parameter in
                guard
                    case let .atom(atom, _) = parameter,
                    case let .symbol(name) = atom
                else {
                    throw MyronError(
                        reason: .typeMismatch,
                        location: expression.getLocation())
                }

                return name
            }

            let expression = elements[2]

            guard let registry = self.registry else {
                fatalError("Evaluator created without registry")
            }

            let inner = Environment(outer: environment, registry: registry)

            let procedure: ([Value]) throws -> Value = { args in
                guard args.count == parameterNames.count else {
                    throw MyronError(
                        reason: .typeMismatch,
                        location: expression.getLocation())
                }

                for (name, value) in zip(parameterNames, args) {
                    inner.insert(name, value: value)
                }

                let value = try self.eval(expression, environment: inner)
                return value
            }

            environment.insert(procedureName, value: .procedure(procedure))
            return .define(procedureName)
        }

        fatalError("evalDefine called with unexpected expression")
    }

    func evalIf(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        guard case let .list(elements, _) = expression else {
            fatalError("evalList called with non-list expression")
        }

        guard elements.count == 4 else {
            throw MyronError(
                reason: .unexpectedArity,
                location: expression.getLocation())
        }

        let condition = elements[1]
        let value = try eval(condition, environment: environment)

        switch value {
        case .boolean(true):
            let branch = elements[2]
            return try eval(branch, environment: environment)
        case .boolean(false):
            let branch = elements[3]
            return try eval(branch, environment: environment)
        default:
            throw MyronError(
                reason: .typeMismatch,
                location: expression.getLocation())
        }
    }

    func evalQuote(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        guard case let .list(elements, _) = expression else {
            fatalError("evalQuote called with non-list expression")
        }

        guard elements.count == 2 else {
            throw MyronError(
                reason: .unexpectedArity,
                location: expression.getLocation())
        }

        let quotation = elements[1]
        return try eval(
            quotation,
            environment: environment,
            inQuoteMode: true)
    }

}

// MARK: - Lists

private extension Evaluator {

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
