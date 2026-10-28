import Foundation

// MARK: - MyronSession

public final class MyronSession {
    private let runtime: MyronRuntime
    private let process: MyronProcess

    init(runtime: MyronRuntime) {
        self.runtime = runtime
        self.process = runtime.makeProcess()
    }

    public convenience init(configuration: MyronSessionConfiguration = .standard) {
        let runtime = MyronRuntime(configuration: configuration)
        self.init(runtime: runtime)
    }

    deinit {
        try? runtime.shutdownProcess(process)
    }

    public func eval(
        _ expression: String,
        sourceHandle: Int? = nil
    ) -> MyronResult {
        runtime.prepareEnvironment(process)
        defer { runtime.tidyEnvironment(process) }

        let (forms, errors) = parse(expression, sourceHandle: sourceHandle)
        guard errors.isEmpty else {
            return .failure(errors)
        }

        guard let lastForm = forms.last else {
            return .nothing
        }

        for form in forms.dropLast() {
            let result = runtime.eval(
                process,
                expression: form,
                containingRepresentation: expression)

            if result.isFailure {
                return result
            }
        }

        let result = runtime.eval(
            process,
            expression: lastForm,
            containingRepresentation: expression)

        return result
    }

    public func evalEach(
        _ expression: String,
        sourceHandle: Int? = nil,
        willEvaluate: (MyronLocation?) -> Void = { _ in },
        didEvaluate: (MyronFormResult) -> Void = { _ in }
    ) -> [MyronFormResult] {
        runtime.prepareEnvironment(process)
        defer { runtime.tidyEnvironment(process) }

        let (forms, errors) = parse(expression, sourceHandle: sourceHandle)
        guard errors.isEmpty else {
            let failure = MyronFormResult(
                location: errors.first?.location,
                result: .failure(errors))
            didEvaluate(failure)
            return [failure]
        }

        let results = forms.map { form in
            willEvaluate(form.location)
            let result = runtime.eval(
                process,
                expression: form,
                containingRepresentation: expression)
            let formResult = MyronFormResult(location: form.location, result: result)
            didEvaluate(formResult)
            return formResult
        }

        return results
    }

}

// MARK: - Evaluation

private extension MyronSession {

    func parse(_ expression: String, sourceHandle: Int?) -> ([Expression], [MyronError]) {
        let lexer = Lexer(input: expression, sourceHandle: sourceHandle)
        let (tokens, lexingErrors) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (forms, parsingErrors) = parser.parse()
        let errors = (lexingErrors + parsingErrors)
            .adorned(style: runtime.configuration.errorStyle, in: expression)

        return (forms, errors)
    }

}

// MARK: - Primitive Definition

extension MyronSession {

    public typealias FnContextArg0 = @Sendable (
        MyronExecutionContext
    ) throws -> MyronValueRepresentable

    public typealias FnContextArg1 = @Sendable (
        MyronExecutionContext,
        MyronValue
    ) throws -> MyronValueRepresentable

    public typealias FnContextArg2 = @Sendable (
        MyronExecutionContext,
        MyronValue,
        MyronValue
    ) throws -> MyronValueRepresentable

    public typealias FnContextArg3 = @Sendable (
        MyronExecutionContext,
        MyronValue,
        MyronValue,
        MyronValue
    ) throws -> MyronValueRepresentable

    public typealias FnContextArg4 = @Sendable (
        MyronExecutionContext,
        MyronValue,
        MyronValue,
        MyronValue,
        MyronValue
    ) throws -> MyronValueRepresentable

    public typealias FnContextArg5 = @Sendable (
        MyronExecutionContext,
        MyronValue,
        MyronValue,
        MyronValue,
        MyronValue,
        MyronValue
    ) throws -> MyronValueRepresentable

    public typealias FnContextArg6 = @Sendable (
        MyronExecutionContext,
        MyronValue,
        MyronValue,
        MyronValue,
        MyronValue,
        MyronValue,
        MyronValue
    ) throws -> MyronValueRepresentable

    public typealias FnContextArgN = @Sendable (
        MyronExecutionContext,
        [MyronValue]
    ) throws -> MyronValueRepresentable

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg0
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context)
            return result.myronValue
        }

        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: .exactly(0),
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg1
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context, args[0])
            return result.myronValue
        }

        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: .exactly(1),
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg2
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context, args[0], args[1])
            return result.myronValue
        }

        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: .exactly(2),
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg3
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context, args[0], args[1], args[2])
            return result.myronValue
        }

        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: .exactly(3),
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg4
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context, args[0], args[1], args[2], args[3])
            return result.myronValue
        }
        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: .exactly(4),
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg5
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context, args[0], args[1], args[2], args[3], args[4])
            return result.myronValue
        }
        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: .exactly(5),
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg6
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context, args[0], args[1], args[2], args[3], args[4], args[5])
            return result.myronValue
        }
        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: .exactly(6),
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        arity: MyronError.IntegerExpectation,
        body: @escaping FnContextArgN
    ) throws {
        let wrapped: MyronPrimitive.ContextualBody = {
            args, context in
            let result = try body(context, args)
            return result.myronValue
        }
        let primitive = try primitivise(
            name: name,
            signature: signature,
            arity: arity,
            wrapped: wrapped)

        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }

    private func primitivise(
        name: String,
        signature: String?,
        arity: MyronError.IntegerExpectation,
        wrapped: @escaping MyronPrimitive.ContextualBody
    ) throws -> MyronPrimitive {
        try Self.validatePrimitiveName(name)

        let checked: MyronPrimitive.ContextualBody = { args, context in
            let location = context.location
            try Self.validatePrimitiveArity(args.count, expected: arity, at: location)
            
            do {
                return try wrapped(args, context)

            } catch let error as MyronError {
                throw error.location == nil ? error.withLocation(location) : error

            } catch let error as MyronHostError {
                throw MyronError(.hostError(error.description), at: location)
                
            } catch {
                let description = String(describing: error)
                throw MyronError(.hostError(description), at: location)
            }
        }

        let primitive = MyronPrimitive(
            id: Counter.next(),
            primitiveName: Self.userNamespace + name,
            representations: [name],
            signature: signature,
            contextualBody: checked)

        switch primitive.signature {
        case .none: break
        case .success(let parsedSignature):
            if let signature {
                let expected: (minimum: Int, maximum: Int?)
                switch arity {
                case .exactly(let count): expected = (count, count)
                case .atLeast(let count): expected = (count, nil)
                case .atMost(let count): expected = (0, count)
                case .unspecified: expected = (0, nil)
                }

                guard parsedSignature.arity == expected else {
                    let explain = "signature arity doesn't match the body arity '\(arity)'"
                    let reason = MyronError.Reason.malformedSignature(signature, explain)
                    throw MyronError(reason)
                }
            }
        case .failure(let error): throw error
        }

        return primitive
    }
    
    private static let userNamespace = "user."

    private static func validatePrimitiveName(_ name: String) throws {
        try MyronValue.validateAsName(name, location: nil)
    }
    
    private static func validatePrimitiveArity(
        _ got: Int,
        expected: MyronError.IntegerExpectation,
        at location: MyronLocation?
    ) throws {
        switch expected {
        case .exactly(let expectation): if got == expectation { return }
        case .atLeast(let expectation): if got >= expectation { return }
        case .atMost(let expectation): if got <= expectation { return }
        case .unspecified: return
        }
        
        throw MyronError(.unexpectedArity(got, expected), at: location)
    }
    
}

// MARK: - Environment Interaction

extension MyronSession {
    
    public func query(_ name: String) -> MyronValue? {
        return try? runtime.query(process, name: name, location: nil)
    }

    public func set(_ name: String, to value: MyronValue) throws {
        try runtime.insert(process, name: name, value: value, location: nil)
    }

    public var names: Set<String> {
        let names = try? runtime.names(process)
        return names ?? Set()
    }

}

// MARK: - Message Handling

extension MyronSession {

    public func send(_ content: MyronValue, to destination: MyronProcess) throws {
        try runtime.send(
            source: process,
            destination: destination,
            content: content,
            location: nil)
    }

}
