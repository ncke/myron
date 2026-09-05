import Foundation

// MARK: - Special Form Constants

extension Evaluator {

    static private let nameDefine = "define"
    static private let nameIf = "if"
    static private let nameLambda = "lambda"
    static private let nameQuote = "quote"
    static private let nameAnd = "and"
    static private let nameOr = "or"

}

// MARK: - Evaluate Special Forms

extension Evaluator {

    func evalSpecialForm(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        guard let name = getSpecialFormName(expression) else {
            throw MyronError(.unimplementedFeature, at: expression.getLocation())
        }

        switch name {

        case Self.nameDefine:
            return try evalDefine(expression, environment: environment)

        case Self.nameIf:
            return try evalIf(expression, environment: environment)

        case Self.nameLambda:
            return try evalLambda(expression, environment: environment)

        case Self.nameQuote:
            return try evalQuote(expression, environment: environment)

        case Self.nameAnd:
            return try evalAnd(expression, environment: environment)

        case Self.nameOr:
            return try evalOr(expression, environment: environment)

        default:
            throw MyronError(.unimplementedFeature, at: expression.getLocation())
        }
    }

}

// MARK: - Special Forms Helpers

extension Evaluator {

    private static let specialFormNames: Set<String> = [
        nameIf, nameDefine, nameLambda, nameQuote, nameAnd, nameOr
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

// MARK: - Lambda

extension Evaluator {

    func evalLambda(_ expression: Expression, environment: Environment) throws -> Value {
        guard case let .list(elements, _) = expression else {
            fatalError("evalLambda called with non-list expression")
        }

        guard elements.count == 3 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        guard case let .list(parameters, _) = elements[1] else {
            throw MyronError(.typeMismatch, at: expression.getLocation())
        }

        let procedure = try makeProcedure(
            parameters: parameters,
            body: elements[2],
            environment: environment)

        return .procedure(procedure)
    }

}

// MARK: - Define

extension Evaluator {

    func makeProcedure(parameters: [Expression], body: Expression, environment: Environment) throws -> Procedure {
        let parameterNames = try parameters.map { parameter in
            guard
                case let .atom(atom, _) = parameter,
                case let .symbol(name) = atom
            else {
                throw MyronError(.typeMismatch, at: body.getLocation())
            }

            return name
        }

        let procedure: ([Value]) throws -> Value = { args in
            guard args.count == parameterNames.count else {
                throw MyronError(.unexpectedArity, at: body.getLocation())
            }

            let inner = Environment(outer: environment, registry: environment.registry)

            for (name, value) in zip(parameterNames, args) {
                inner.insert(name, value: value)
            }

            let value = try self.eval(body, environment: inner)
            return value
        }

        return procedure
    }

    func evalDefine(_ expression: Expression, environment: Environment) throws -> Value {
        guard case let .list(elements, _) = expression else {
            fatalError("evalList called with non-list expression")
        }

        guard elements.count == 3 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        let nameExpression = elements[1]

        if case .atom(let atom, _) = nameExpression {
            guard case .symbol(let name) = atom else {
                throw MyronError(.typeMismatch, at: expression.getLocation())
            }

            let value = try eval(elements[2], environment: environment)
            environment.insert(name, value: value)
            return .define(name)
        }

        if case .list(let parameters, _) = nameExpression {
            guard parameters.count > 0 else {
                throw MyronError(.unexpectedArity, at: expression.getLocation())
            }

            guard
                case let .atom(atom, _) = parameters.first,
                case .symbol(let procedureName) = atom
            else {
                throw MyronError(.typeMismatch, at: expression.getLocation())
            }

            let procedure = try makeProcedure(
                parameters: Array(parameters.dropFirst()),
                body: elements[2],
                environment: environment)

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
            throw MyronError(.unexpectedArity, at: expression.getLocation())
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
            throw MyronError(.typeMismatch, at: expression.getLocation())
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
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        let quotation = elements[1]
        return try eval(quotation, environment: environment, inQuoteMode: true)
    }

}

// MARK: - Shortcircuit And Or

extension Evaluator {

    func evalAnd(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        guard case let .list(terms, _) = expression else {
            fatalError("evalAnd called with non-list expression")
        }

        guard terms.count > 1 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        for term in terms[1...] {
            let value = try eval(term, environment: environment)

            guard case .boolean(let bool) = value else {
                let reason = MyronError.Reason.unexpectedType(value.kind, [.boolean])
                throw MyronError(reason, at: expression.getLocation())
            }

            if !bool { return .boolean(false) }
        }

        return .boolean(true)
    }

    func evalOr(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        guard case let .list(terms, _) = expression else {
            fatalError("evalOr called with non-list expression")
        }

        guard terms.count > 1 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        for term in terms[1...] {
            let value = try eval(term, environment: environment)

            guard case .boolean(let bool) = value else {
                let reason = MyronError.Reason.unexpectedType(value.kind, [.boolean])
                throw MyronError(reason, at: expression.getLocation())
            }

            if bool { return .boolean(true) }
        }

        return .boolean(false)
    }

}
