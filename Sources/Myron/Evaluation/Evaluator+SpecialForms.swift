import Foundation

// MARK: - Special Form Constants

extension Evaluator {

    static private let nameBegin = "begin"
    static private let nameDefine = "define"
    static private let nameIf = "if"
    static private let nameLambda = "lambda"
    static private let nameLet = "let"
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

        case Self.nameBegin:
            return try evalBegin(expression, environment: environment)

        case Self.nameDefine:
            return try evalDefine(expression, environment: environment)

        case Self.nameIf:
            return try evalIf(expression, environment: environment)

        case Self.nameLambda:
            return try evalLambda(expression, environment: environment)

        case Self.nameLet:
            return try evalLet(expression, environment: environment)

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
        nameBegin, nameDefine, nameIf, nameLambda, nameLet, nameQuote, nameAnd, nameOr
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

// MARK: - Eval Sequence

extension Evaluator {

    func evalSequence(_ body: ArraySlice<Expression>, environment: Environment) throws -> Value {
        var result = Value.nothing
        for expression in body {
            result = try eval(expression, environment: environment)
        }

        return result
    }

}

// MARK: - Lambda

extension Evaluator {

    func evalLambda(_ expression: Expression, environment: Environment) throws -> Value {
        let (elements, _) = try expression.unwrapList(#function)

        guard elements.count >= 3 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        guard case let .list(parameters, _) = elements[1] else {
            throw MyronError(.typeMismatch, at: expression.getLocation())
        }

        let procedure = try makeProcedure(
            parameters: parameters,
            bodies: elements[2...],
            environment: environment,
            location: expression.getLocation())

        return .procedure(procedure)
    }

}

// MARK: - Begin

extension Evaluator {

    func evalBegin(_ expression: Expression, environment: Environment) throws -> Value {
        let (subexpressions, _) = try expression.unwrapList(#function)
        guard subexpressions.count > 1 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        return try evalSequence(subexpressions[1...], environment: environment)
    }

}

// MARK: - Let

extension Evaluator {

    func evalLet(_ expression: Expression, environment: Environment) throws -> Value {
        let (subexpressions, _) = try expression.unwrapList(#function)
        guard subexpressions.count > 2 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        guard case let .list(bindings, _) = subexpressions[1] else {
            throw MyronError(.expectedBindingsForLet, at: subexpressions[1].getLocation())
        }

        let scoped = Environment(outer: environment, registry: environment.registry)

        for binding in bindings {
            guard
                case let .list(pair, _) = binding,
                pair.count == 2,
                case let .atom(nameAtom, _) = pair[0],
                case let .symbol(bindingName) = nameAtom
            else {
                throw MyronError(.invalidBindingForLet, at: binding.getLocation())
            }

            let value = try eval(pair[1], environment: scoped)
            scoped.insert(bindingName, value: value)
        }

        let result = try evalSequence(subexpressions[2...], environment: scoped)
        return result
    }

}

// MARK: - Define

extension Evaluator {

    func evalDefine(_ expression: Expression, environment: Environment) throws -> Value {
        let (elements, _) = try expression.unwrapList(#function)
        guard elements.count >= 3 else {
            throw MyronError(.unexpectedArity, at: expression.getLocation())
        }

        let nameExpression = elements[1]

        switch nameExpression {

        case .atom(let atom, _):
            guard elements.count == 3 else {
                throw MyronError(.unexpectedArity, at: expression.getLocation())
            }

            guard case .symbol(let name) = atom else {
                throw MyronError(.typeMismatch, at: expression.getLocation())
            }

            let value = try eval(elements[2], environment: environment)
            environment.insert(name, value: value)
            return .define(name)

        case .list(let parameters, _):
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
                bodies: elements[2...],
                environment: environment,
                location: expression.getLocation())

            environment.insert(procedureName, value: .procedure(procedure))
            return .define(procedureName)
        }
    }

    func makeProcedure(
        parameters: [Expression],
        bodies: ArraySlice<Expression>,
        environment: Environment,
        location: Range<Int>?
    ) throws -> Procedure {
        let parameterNames = try parameters.map { parameter in
            guard
                case let .atom(atom, _) = parameter,
                case let .symbol(name) = atom
            else {
                throw MyronError(.typeMismatch, at: parameter.getLocation())
            }

            return name
        }

        let procedure: ([Value]) throws -> Value = { args in
            guard args.count == parameterNames.count else {
                throw MyronError(.unexpectedArity, at: location)
            }

            let inner = Environment(outer: environment, registry: environment.registry)

            for (name, value) in zip(parameterNames, args) {
                inner.insert(name, value: value)
            }

            let value = try self.evalSequence(bodies, environment: inner)
            return value
        }

        return procedure
    }

}

// MARK: - If

private extension Evaluator {

    func evalIf(
        _ expression: Expression,
        environment: Environment
    ) throws -> Value {
        let (elements, _) = try expression.unwrapList(#function)

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
        let (elements, _) = try expression.unwrapList(#function)

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
        let (terms, _) = try expression.unwrapList(#function)

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
        let (terms, _) = try expression.unwrapList(#function)

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
