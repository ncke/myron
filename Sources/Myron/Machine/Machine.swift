import Foundation

// MARK: - Machine

final class Machine {
    private let maximumStackDepth: Int?
    private let rootEnvironment: Environment
    private var stack = [Frame]()
    private var control = Control.value(.nothing)

    init(
        environment: Environment,
        maximumStackDepth: Int? = nil
    ) {
        self.maximumStackDepth = maximumStackDepth
        self.rootEnvironment = environment
    }

}

// MARK: - Frame and Control

extension Machine {

    enum Frame {
        case arguments(ArraySlice<Expression>, [Value], Environment, Location?)
        case bind(String, ArraySlice<Expression>, ArraySlice<Expression>, Environment, Location?)
        case branch(Expression, Expression, Environment, Location?)
        case condition(ArraySlice<Expression>, ArraySlice<Expression>, Environment, Location?)
        case conjunction(ArraySlice<Expression>, Environment, Location?)
        case define(String, Environment)
        case disjunction(ArraySlice<Expression>, Environment, Location?)
        case filtering(Value, Value, ArraySlice<Value>, [Value], Location?)
        case mapping(Value, ArraySlice<Value>, [Value], Location?)
        case probing(HigherProbe, Value, ArraySlice<Value>, Location?)
        case reducing(Value, ArraySlice<Value>, Location?)
        case sequence(ArraySlice<Expression>, Environment, Location?)
    }

    enum Control {
        case eval(Expression, Environment)
        case value(Value)
    }

}

// MARK: - Eval

extension Machine {

    func eval(_ expression: Expression) throws -> Value {
        stack = []
        control = .eval(expression, rootEnvironment)
        return try run()
    }

    private func checkStackDepth(at location: @autoclosure () -> Location?) throws {
        guard let limit = maximumStackDepth, stack.count > limit else { return }

        throw MyronError(
            .exceededMaximumStackDepth(stack.count),
            at: location())
    }

    private func run() throws -> Value {
        while true {
            switch control {

            case .eval(let expression, let environment):
                try step(expression: expression, environment: environment)
                try checkStackDepth(at: expression.getLocation())

            case .value(let value):
                guard let frame = stack.popLast() else { return value }
                try kontinue(frame, with: value)
            }
        }
    }

}

// MARK: - Step

extension Machine {

    private func step(expression: Expression, environment: Environment) throws {
        switch expression {

        case .atom(.symbol(let name), let meta):
            guard let value = environment.lookup(name) else {
                throw MyronError(.unrecognisedSymbol, at: meta.location)
            }
            control = .value(value)

        case .atom(let atom, _):
            let value = Value.makeValue(from: atom)
            control = .value(value)

        case .list(let elements, let meta):
            guard let head = elements.first else {
                throw MyronError(.emptyApplication, at: meta.location)
            }
            let tail = elements.dropFirst()

            if let (frame, control) = try interpretSpecialForm(
                head: head,
                tail: tail,
                meta: meta,
                environment: environment
            ) {
                if let frame { stack.append(frame) }
                self.control = control
                return
            }

            stack.append(.arguments(tail, [], environment, meta.location))
            control = .eval(head, environment)
        }
    }

}

// MARK: - Special Forms

extension Machine {

    private func interpretSpecialForm(
        head: Expression,
        tail: ArraySlice<Expression>,
        meta: Expression.Metadata,
        environment: Environment
    ) throws -> (Frame?, Control)? {
        guard case .atom(.symbol(let formName), _) = head else { return nil }

        switch formName {

        case "and":
            guard let headClause = tail.first else {
                throw MyronError(.unexpectedArity(tail.count, .atLeast(1)), at: meta.location)
            }

            let frame = Frame.conjunction(tail.dropFirst(), environment, meta.location)
            let control = Control.eval(headClause, environment)
            return (frame, control)

        case "begin":
            if tail.count == 0 {
                return (nil, .value(.nothing))
            }

            if tail.count > 1 {
                let frame = Frame.sequence(tail.dropFirst(), environment, meta.location)
                let control = Control.eval(tail[tail.startIndex], environment)
                return (frame, control)
            } else {
                let control = Control.eval(tail[tail.startIndex], environment)
                return (nil, control)
            }

        case "cond":
            guard tail.count >= 1 else {
                throw MyronError(.unexpectedArity(tail.count, .atLeast(1)), at: meta.location)
            }

            let (headList, hmeta) = try tail[tail.startIndex].unwrapList()
            guard headList.count >= 1 else {
                throw MyronError(.unexpectedArity(headList.count, .atLeast(1)), at: hmeta.location)
            }

            let condition = headList[headList.startIndex]
            let bodies = headList[headList.index(after: headList.startIndex)...]
            let frame = Frame.condition(bodies, tail.dropFirst(), environment, meta.location)
            let control = Control.eval(condition, environment)
            return (frame, control)

        case "define":
            guard tail.count >= 2 else {
                throw MyronError(.unexpectedArity(tail.count, .atLeast(2)), at: meta.location)
            }

            let signatureExpression = tail[tail.startIndex]

            if let name = signatureExpression.asSymbolName() {
                guard tail.count == 2 else {
                    throw MyronError(.unexpectedArity(tail.count, .exactly(2)), at: meta.location)
                }

                let definition = tail[tail.startIndex + 1]
                let frame = Frame.define(name, environment)
                let control = Control.eval(definition, environment)
                return (frame, control)
            }

            guard let signature = signatureExpression.asList() else {
                let reason = MyronError.Reason.unexpectedType(
                    signatureExpression.asValueKind(),
                    [.symbol, .list])
                throw MyronError(reason, at: signatureExpression.getLocation())
            }

            guard let nameExpression = signature.first else {
                throw MyronError(
                    .unexpectedArity(0, .atLeast(1)),
                    at: signatureExpression.getLocation())
            }

            let name = try nameExpression.unwrapSymbolName()
            let parameters = try signature.dropFirst().map { expr in try expr.unwrapSymbolName() }
            let bodies = Array(tail.dropFirst())
            let procedure = Procedure(
                parameters: parameters,
                bodies: bodies,
                environment: environment)
            let frame = Frame.define(name, environment)
            let control = Control.value(.procedure(procedure))
            return (frame, control)

        case "if":
            guard tail.count == 3 else {
                throw MyronError(.unexpectedArity(tail.count, .exactly(3)), at: meta.location)
            }

            let condition = tail[tail.startIndex]
            let thenClause = tail[tail.startIndex + 1]
            let elseClause = tail[tail.startIndex + 2]
            let frame = Frame.branch(thenClause, elseClause, environment, meta.location)
            let control = Control.eval(condition, environment)
            return (frame, control)

        case "lambda":
            guard tail.count >= 2 else {
                throw MyronError(.unexpectedArity(tail.count, .atLeast(2)), at: meta.location)
            }

            guard let parameterExpressions = tail[tail.startIndex].asList() else {
                let got = tail[tail.startIndex].asValueKind()
                let reason = MyronError.Reason.unexpectedType(got, [.list])
                throw MyronError(reason, at: tail[tail.startIndex].getLocation())
            }

            let parameters = try parameterExpressions.map { expr in try expr.unwrapSymbolName() }
            let bodies = Array(tail.dropFirst())
            let procedure = Procedure(
                parameters: parameters,
                bodies: bodies,
                environment: environment)
            let control = Control.value(.procedure(procedure))
            return (nil, control)

        case "let":
            guard tail.count >= 2 else {
                throw MyronError(.unexpectedArity(tail.count, .atLeast(2)), at: meta.location)
            }

            guard let bindingExprs = tail[tail.startIndex].asList() else {
                let got = tail[tail.startIndex].asValueKind()
                let reason = MyronError.Reason.unexpectedType(got, [.list])
                throw MyronError(reason, at: tail[tail.startIndex].getLocation())
            }

            let bodies = tail.dropFirst()
            let inner = Environment(outer: environment)

            guard let headBinding = bindingExprs.first else {
                var frame: Frame? = nil
                if bodies.count > 1 {
                    frame = Frame.sequence(bodies.dropFirst(), inner, meta.location)
                }

                let control: Control
                if let firstBody = bodies.first {
                    control = Control.eval(firstBody, inner)
                } else {
                    control = Control.value(.nothing)
                }

                return (frame, control)
            }

            let (name, expr) = try headBinding.unwrapBinding()

            let frame = Frame.bind(name, bindingExprs.dropFirst(), bodies, inner, meta.location)
            let control = Control.eval(expr, inner)
            return (frame, control)

        case "or":
            guard let headClause = tail.first else {
                throw MyronError(.unexpectedArity(tail.count, .atLeast(1)), at: meta.location)
            }

            let frame = Frame.disjunction(tail.dropFirst(), environment, meta.location)
            let control = Control.eval(headClause, environment)
            return (frame, control)

        case "quote":
            guard tail.count == 1 else {
                throw MyronError(.unexpectedArity(tail.count, .exactly(1)), at: meta.location)
            }

            let quotation = tail[tail.startIndex]
            let value = Value.makeValue(from: quotation)
            let control = Control.value(value)
            return (nil, control)


        default: return nil
        }
    }

}

// MARK: - Kontinue

extension Machine {

    private func kontinue(_ frame: Frame, with value: Value) throws {
        switch frame {

        case .arguments(let remaining, var done, let environment, let location):
            done.append(value)

            if let next = remaining.first {
                stack.append(.arguments(remaining.dropFirst(), done, environment, location))
                control = .eval(next, environment)
            } else {
                let head = done.first!
                try apply(head, to: done.dropFirst(), at: location)
            }

        case .bind(let name, let remaining, let bodies, let environment, let location):
            environment.insert(name, value: value)
            if let next = remaining.first {
                let (name, expr) = try next.unwrapBinding()
                stack.append(.bind(name, remaining.dropFirst(), bodies, environment, location))
                control = .eval(expr, environment)
                return
            }

            if bodies.count > 1 {
                stack.append(.sequence(bodies.dropFirst(), environment, location))
            }

            if let firstBody = bodies.first {
                control = .eval(firstBody, environment)
            }

        case .branch(let thenClause, let elseClause, let environment, let location):
            let condition = try value.unwrapBoolean(location)
            control = .eval(condition ? thenClause : elseClause, environment)

        case .condition(let bodies, let remaining, let environment, let location):
            if try value.unwrapBoolean(location) == true {
                if bodies.count > 1 {
                    stack.append(.sequence(bodies.dropFirst(), environment, location))
                }
                if let firstBody = bodies.first {
                    control = .eval(firstBody, environment)
                } else {
                    control = .value(.nothing)
                }

                return
            }

            if let (list, meta) = try remaining.first?.unwrapList() {
                guard list.count >= 1 else {
                    throw MyronError(.unexpectedArity(list.count, .atLeast(1)), at: meta.location)
                }

                let condition = list[list.startIndex]
                let bodies = list[list.index(after: list.startIndex)...]
                stack.append(.condition(bodies, remaining.dropFirst(), environment, location))
                control = .eval(condition, environment)
            } else {
                control = .value(.nothing)
            }

        case .conjunction(let remaining, let environment, let location):
            if try value.unwrapBoolean(location) == false {
                control = .value(.boolean(false))
            } else if let next = remaining.first {
                stack.append(.conjunction(remaining.dropFirst(), environment, location))
                control = .eval(next, environment)
            } else {
                control = .value(.boolean(true))
            }

        case .disjunction(let remaining, let environment, let location):
            if try value.unwrapBoolean(location) == true {
                control = .value(.boolean(true))
            } else if let next = remaining.first {
                stack.append(.disjunction(remaining.dropFirst(), environment, location))
                control = .eval(next, environment)
            } else {
                control = .value(.boolean(false))
            }

        case .filtering(let function, let element, let remaining, var done, let location):
            let include = try value.unwrapBoolean(location)
            if include {
                done.append(element)
            }

            if let next = remaining.first {
                stack.append(.filtering(function, next, remaining.dropFirst(), done, location))
                try apply(function, to: [next], at: location)
                return
            }

            control = .value(.list(done))

        case .mapping(let function, let remaining, var done, let location):
            done.append(value)

            if let next = remaining.first {
                stack.append(.mapping(function, remaining.dropFirst(), done, location))
                try apply(function, to: [next], at: location)
                return
            }

            control = .value(.list(done))

        case .probing(let higher, let function, let remaining, let location):
            let result = try value.unwrapBoolean(location)

            switch higher {
            case .all: if !result { control = .value(.boolean(false)); return }
            case .any: if result { control = .value(.boolean(true)); return }
            }

            if let next = remaining.first {
                stack.append(.probing(higher, function, remaining.dropFirst(), location))
                try apply(function, to: [next], at: location)
                return
            }

            switch higher {
            case .all: control = .value(.boolean(true))
            case .any: control = .value(.boolean(false))
            }

        case .reducing(let function, let remaining, let location):
            if let next = remaining.first {
                stack.append(.reducing(function, remaining.dropFirst(), location))
                try apply(function, to: [value, next], at: location)
                return
            }

            control = .value(value)

        case .sequence(let remaining, let environment, let location):
            if let next = remaining.first {
                if remaining.count > 1 {
                    stack.append(.sequence(remaining.dropFirst(), environment, location))
                }
                control = .eval(next, environment)
            } else {
                control = .value(value)
            }

        case .define(let name, let environment):
            environment.insert(name, value: value)
            control = .value(.define(name))

        }
    }

}

// MARK: - Apply

extension Machine {

    private func apply(
        _ value: Value,
        to arguments: ArraySlice<Value>,
        at location: Location?
    ) throws {
        switch value {

        case .higherOrder(let higher):
            switch higher {

            case .map:
                let (function, valueList) = try arguments.unwrap2(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }
                let values = try valueList.unwrapList(location)

                if let headValue = values.first {
                    stack.append(.mapping(function, values.dropFirst(), [], location))
                    try apply(function, to: [headValue], at: location)
                } else {
                    control = .value(.list([]))
                }

            case .reduce:
                let (function, partial, valueList) = try arguments.unwrap3(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }
                let values = try valueList.unwrapList(location)

                if let headValue = values.first {
                    stack.append(.reducing(function, values.dropFirst(), location))
                    try apply(function, to: [partial, headValue], at: location)
                } else {
                    control = .value(partial)
                }

            case .filter:
                let (function, valueList) = try arguments.unwrap2(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }
                let values = try valueList.unwrapList(location)

                if let headValue = values.first {
                    stack.append(.filtering(function, headValue, values.dropFirst(), [], location))
                    try apply(function, to: [headValue], at: location)
                } else {
                    control = .value(.list([]))
                }
            }

        case .higherProbe(let higher):
            let (function, valueList) = try arguments.unwrap2(location)
            guard function.isCallable else {
                throw MyronError(.expectedFunction(function.kind), at: location)
            }
            let values = try valueList.unwrapList(location)

            if let headValue = values.first {
                stack.append(.probing(higher, function, values.dropFirst(), location))
                try apply(function, to: [headValue], at: location)
            } else {
                switch higher {
                case .all: control = .value(.boolean(true))
                case .any: control = .value(.boolean(false))
                }
            }

        case .primitive(let function):
            let result = try function(Array(arguments), location)
            control = .value(result)

        case .procedure(let procedure):
            guard procedure.parameters.count == arguments.count else {
                let got = arguments.count
                let expected = procedure.parameters.count
                let reason = MyronError.Reason.unexpectedArity(got, .exactly(expected))
                throw MyronError(reason, at: location)
            }

            let inner = Environment(outer: procedure.environment)
            for (name, argument) in zip(procedure.parameters, arguments) {
                inner.insert(name, value: argument)
            }

            let bodies = procedure.bodies
            guard bodies.count > 0 else {
                throw MyronError(.internalError("`apply` encountered empty bodies"), at: location)
            }

            if bodies.count > 1 {
                stack.append(.sequence(bodies.dropFirst(), inner, location))
            }

            control = .eval(bodies[0], inner)

        default:
            throw MyronError(.expectedFunction(value.kind), at: location)
        }
    }

}
