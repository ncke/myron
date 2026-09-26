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
        case arguments(ArraySlice<Expression>, [MyronValue], Environment, MyronLocation?)
        case bind(String, ArraySlice<Expression>, ArraySlice<Expression>, Environment, MyronLocation?)
        case branch(Expression, Expression, Environment, MyronLocation?)
        case condition(ArraySlice<Expression>, ArraySlice<Expression>, Environment, MyronLocation?)
        case conjunction(ArraySlice<Expression>, Environment, MyronLocation?)
        case define(String, Environment)
        case disjunction(ArraySlice<Expression>, Environment, MyronLocation?)
        case filtering(MyronValue, MyronValue, ArraySlice<MyronValue>, [MyronValue], Shape, MyronLocation?)
        case foldring(MyronValue, ArraySlice<MyronValue>, MyronLocation?)
        case mapping(MyronValue, ArraySlice<MyronValue>, [MyronValue], Shape, MyronLocation?)
        case probing(MyronHigherProbe, MyronValue, ArraySlice<MyronValue>, MyronLocation?)
        case reducing(MyronValue, ArraySlice<MyronValue>, MyronLocation?)
        case sequence(ArraySlice<Expression>, Environment, MyronLocation?)
    }

    enum Control {
        case eval(Expression, Environment)
        case value(MyronValue)
    }
    
    enum Shape {
        case list, set

        init(_ value: MyronValue) throws {
            switch value.kind {
            case .list: self = .list
            case .set: self = .set
            default:
                let explain = "unexpected kind for shape initialiser, got: \(value.kind)"
                throw MyronError(.internal(explain))
            }
        }

        func rebuild(_ elements: [MyronValue]) -> MyronValue {
            switch self {
            case .list: return .list(elements)
            case .set: return .set(MyronSet(array: elements))
            }
        }
    }

}

// MARK: - Eval

extension Machine {

    func eval(_ expression: Expression) throws -> MyronValue {
        stack = []
        control = .eval(expression, rootEnvironment)
        return try run()
    }

    private func checkStackDepth(at location: @autoclosure () -> MyronLocation?) throws {
        guard let limit = maximumStackDepth, stack.count > limit else { return }

        throw MyronError(
            .exceededMaximumStackDepth(stack.count),
            at: location())
    }

    private func run() throws -> MyronValue {
        while true {
            switch control {

            case .eval(let expression, let environment):
                try step(expression: expression, environment: environment)
                try checkStackDepth(at: expression.location)

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
            let value = MyronValue.makeValue(from: atom)
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
    
    private static let specialAnd = "and"
    private static let specialBegin = "begin"
    private static let specialCond = "cond"
    private static let specialDefine = "define"
    private static let specialIf = "if"
    private static let specialLambda = "lambda"
    private static let specialLet = "let"
    private static let specialOr = "or"
    private static let specialQuote = "quote"
    
    static let specialFormNames = Set([
        specialAnd, specialBegin, specialCond, specialDefine, specialIf,
        specialLambda, specialLet, specialOr, specialQuote
    ])
    
    private func interpretSpecialForm(
        head: Expression,
        tail: ArraySlice<Expression>,
        meta: Expression.Metadata,
        environment: Environment
    ) throws -> (Frame?, Control)? {
        guard let formName = head.asSymbolName() else { return nil }

        switch formName {

        case Self.specialAnd:
            let (clause, remainder) = try tail.headtail(meta.location)
            let frame = Frame.conjunction(remainder, environment, meta.location)
            let control = Control.eval(clause, environment)
            return (frame, control)

        case Self.specialBegin:
            if tail.count == 0 {
                return (nil, .value(.nothing))
            } else if tail.count > 1 {
                return (
                    .sequence(tail.dropFirst(), environment, meta.location),
                    .eval(tail[tail.startIndex], environment))
            } else {
                return (nil, .eval(tail[tail.startIndex], environment))
            }

        case Self.specialCond:
            let (clause, remainder) = try tail.headtail(meta.location)
            let (condition, bodies) = try clause.headtail()
            return (
                .condition(bodies, remainder, environment, meta.location),
                .eval(condition, environment))

        case Self.specialDefine:
            try tail.mustHaveAtLeast(2, meta.location)
            let sigExpression = tail[tail.startIndex]

            if let name = sigExpression.asSymbolName() {
                try tail.mustHaveExactly(2, meta.location)
                let definition = tail[tail.startIndex + 1]
                return (.define(name, environment), .eval(definition, environment))
            }

            guard let sigList = sigExpression.asList() else {
                let got = sigExpression.asValueKind()
                let reason = MyronError.Reason.unexpectedType(got, [.symbol, .list])
                throw MyronError(reason, at: sigExpression.location)
            }

            let (nameExpr, paramExprs) = try sigList.headtail(sigExpression.location)
            let name = try nameExpr.unwrapSymbolName()
            let params = try paramExprs.map { expr in try expr.unwrapSymbolName() }
            let bodies = Array(tail[(tail.startIndex + 1)...])
            let proc = MyronProcedure(parameters: params, bodies: bodies, environment: environment)
            return (.define(name, environment), .value(.procedure(proc)))

        case Self.specialIf:
            let (condition, thenClause, elseClause) = try tail.unwrap3(meta.location)
            return (
                .branch(thenClause, elseClause, environment, meta.location),
                .eval(condition, environment))

        case Self.specialLambda:
            try tail.mustHaveAtLeast(2, meta.location)
            let (head, remainder) = try tail.headtail(meta.location)
            let (paramExprs, _) = try head.unwrapList()
            let params = try paramExprs.map { expr in try expr.unwrapSymbolName() }
            let bodies = Array(remainder)
            let proc = MyronProcedure(parameters: params, bodies: bodies, environment: environment)
            return (nil, .value(.procedure(proc)))

        case Self.specialLet:
            try tail.mustHaveAtLeast(2, meta.location)
            let (head, bodies) = try tail.headtail(meta.location)
            let (bindingExprs, _) = try head.unwrapList()
            let inner = try Environment(outer: environment, at: meta.location)

            if let headBinding = bindingExprs.first {
                let (name, expr) = try headBinding.unwrapBinding()
                return (
                    .bind(name, bindingExprs.dropFirst(), bodies, inner, meta.location),
                    .eval(expr, inner))
            }

            guard let firstBody = bodies.first else {
                let explain = "`let` must have at least one binding and one body"
                throw MyronError(.internal(explain), at: meta.location)
            }

            let frame = bodies.count > 1
            ? Frame.sequence(bodies.dropFirst(), inner, meta.location)
            : nil
            return (frame, .eval(firstBody, inner))

        case Self.specialOr:
            let (clause, remainder) = try tail.headtail(meta.location)
            return (.disjunction(remainder, environment, meta.location), .eval(clause, environment))

        case Self.specialQuote:
            let quotation = try tail.unwrap1(meta.location)
            let value = try MyronValue.makeValue(from: quotation, at: meta.location)
            return (nil, .value(value))

        default: return nil
        }
    }

}

// MARK: - Kontinue

extension Machine {

    private func kontinue(_ frame: Frame, with value: MyronValue) throws {
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

        case .define(let name, let environment):
            environment.insert(name, value: value)
            control = .value(.define(name))

        case .disjunction(let remaining, let environment, let location):
            if try value.unwrapBoolean(location) == true {
                control = .value(.boolean(true))
            } else if let next = remaining.first {
                stack.append(.disjunction(remaining.dropFirst(), environment, location))
                control = .eval(next, environment)
            } else {
                control = .value(.boolean(false))
            }

        case .filtering(let function, let element, let remaining, var done, let shape, let location):
            let include = try value.unwrapBoolean(location)
            if include {
                done.append(element)
            }

            if let next = remaining.first {
                stack.append(.filtering(function, next, remaining.dropFirst(), done, shape, location))
                try apply(function, to: [next], at: location)
                return
            }

            control = .value(shape.rebuild(done))

        case .foldring(let function, let remaining, let location):
            if let next = remaining.last {
                stack.append(.foldring(function, remaining.dropLast(), location))
                try apply(function, to: [next, value], at: location)
                return
            }

            control = .value(value)

        case .mapping(let function, let remaining, var done, let shape, let location):
            done.append(value)

            if let next = remaining.first {
                stack.append(.mapping(function, remaining.dropFirst(), done, shape, location))
                try apply(function, to: [next], at: location)
                return
            }

            control = .value(shape.rebuild(done))

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
        }
    }

}

// MARK: - Apply

extension Machine {

    private func apply(
        _ value: MyronValue,
        to arguments: ArraySlice<MyronValue>,
        at location: MyronLocation?
    ) throws {
        switch value {

        case .higherOrder(let higher):
            switch higher {

            case .apply:
                try arguments.mustHaveAtLeast(2, location)

                let function = try arguments.unwrapFirst(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }

                guard let last = arguments.last else {
                    let explain = "apply must have at least two arguments"
                    throw MyronError(.internal(explain), at: location)
                }

                var values = arguments.dropFirst().dropLast()
                values.append(contentsOf: try last.unwrapElements(location))
                try apply(function, to: values, at: location)

            case .map:
                let (function, valueList) = try arguments.unwrap2(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }
                let values = try valueList.unwrapElements(location)
                let shape = try Shape(valueList)

                if let headValue = values.first {
                    stack.append(.mapping(function, values.dropFirst(), [], shape, location))
                    try apply(function, to: [headValue], at: location)
                } else {
                    control = .value(shape.rebuild([]))
                }

            case .foldr:
                let (function, partial, valueList) = try arguments.unwrap3(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }
                let values = try valueList.unwrapElements(location)
                
                if let tailValue = values.last {
                    stack.append(.foldring(function, values.dropLast(), location))
                    try apply(function, to: [tailValue, partial], at: location)
                } else {
                    control = .value(partial)
                }

            case .filter:
                let (function, valueList) = try arguments.unwrap2(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }
                let values = try valueList.unwrapElements(location)
                let shape = try Shape(valueList)

                if let headValue = values.first {
                    stack.append(
                        .filtering(function, headValue, values.dropFirst(), [], shape, location))
                    try apply(function, to: [headValue], at: location)
                } else {
                    control = .value(shape.rebuild([]))
                }

            case .reduce:
                let (function, partial, valueList) = try arguments.unwrap3(location)
                guard function.isCallable else {
                    throw MyronError(.expectedFunction(function.kind), at: location)
                }
                let values = try valueList.unwrapElements(location)

                if let headValue = values.first {
                    stack.append(.reducing(function, values.dropFirst(), location))
                    try apply(function, to: [partial, headValue], at: location)
                } else {
                    control = .value(partial)
                }
            }

        case .higherProbe(let higher):
            let (function, valueList) = try arguments.unwrap2(location)
            guard function.isCallable else {
                throw MyronError(.expectedFunction(function.kind), at: location)
            }
            let values = try valueList.unwrapElements(location)

            if let headValue = values.first {
                stack.append(.probing(higher, function, values.dropFirst(), location))
                try apply(function, to: [headValue], at: location)
            } else {
                switch higher {
                case .all: control = .value(.boolean(true))
                case .any: control = .value(.boolean(false))
                }
            }
            
        case .primitive(let primitive):
            let result = try primitive.call(Array(arguments), at: location)
            control = .value(result)

        case .procedure(let procedure):
            guard procedure.parameters.count == arguments.count else {
                let got = arguments.count
                let expected = procedure.parameters.count
                let reason = MyronError.Reason.unexpectedArity(got, .exactly(expected))
                throw MyronError(reason, at: location)
            }

            let inner = try Environment(outer: procedure.environment, at: location)
            for (name, argument) in zip(procedure.parameters, arguments) {
                inner.insert(name, value: argument)
            }

            let bodies = procedure.bodies
            guard bodies.count > 0 else {
                throw MyronError(.internal("`apply` encountered empty bodies"), at: location)
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
