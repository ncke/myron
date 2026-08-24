import Foundation

// MARK: - Evaluate Special Forms

extension Evaluator {

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

}

// MARK: - Special Forms Helpers

extension Evaluator {

    private static let specialFormNames: Set<String> = [
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

}

// MARK: - Define

extension Evaluator {

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

            let procedure: ([Value]) throws -> Value = { args in
                guard args.count == parameterNames.count else {
                    throw MyronError(
                        reason: .typeMismatch,
                        location: expression.getLocation())
                }

                let inner = Environment(outer: environment, registry: environment.registry)

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

}

// MARK: - If

private extension Evaluator {

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

}

// MARK: - Quote

extension Evaluator {

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
