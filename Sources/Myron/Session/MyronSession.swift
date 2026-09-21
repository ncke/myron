import Foundation

// MARK: - MyronSession

public final class MyronSession {
    private let configuration: MyronSessionConfiguration
    private let environment: Environment
    private let environmentRegistry: EnvironmentRegistry
    private let machine: Machine

    public init(configuration: MyronSessionConfiguration = .standard) {
        self.configuration = configuration
        self.environmentRegistry = EnvironmentRegistry()
        self.environment = Environment(registry: environmentRegistry)
        self.machine = Machine(
            environment: environment,
            maximumStackDepth: configuration.maximumStackDepth)
    }

    deinit {
         environmentRegistry.shutdownAll()
    }

    public func eval(
        _ expression: String,
        sourceHandle: Int? = nil
    ) -> MyronResult {
        defer { environmentRegistry.tidy() }
        environmentRegistry.resetTidyTrigger()
        let lexer = Lexer(input: expression, sourceHandle: sourceHandle)
        let (tokens, lexingErrors) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (forms, parsingErrors) = parser.parse()

        guard lexingErrors.isEmpty, parsingErrors.isEmpty else {
            let errors = lexingErrors + parsingErrors
            let adornedErrors = adornErrorsIfNecessary(errors, in: expression)
            return .failure(adornedErrors)
        }

        let silentForms = forms.dropLast()

        guard let lastForm = forms.last else {
            return .nothing
        }

        func caughtEval(_ form: Expression) -> MyronResult {
            do {
                let value = try machine.eval(form)
                return .success(value)

            } catch let error as MyronError {
                let adornedError = adornErrorIfNecessary(error, in: expression)
                return .failure([adornedError])

            } catch {
                let message = "unhandled error type: \(error)"
                let error = MyronError(.internal(message), at: form.location)
                let adornedError = adornErrorIfNecessary(error, in: expression)
                return .failure([adornedError])
            }
        }

        for form in silentForms {
            let result = caughtEval(form)
            if result.isFailure {
                return result
            }
        }

        let result = caughtEval(lastForm)
        return result
    }

}

// MARK: - Primitive Definition

extension MyronSession {
    
    public func define(
        _ name: String,
        body: @escaping @Sendable () throws -> MyronValueRepresentable
    ) throws {
        let wrapped: MyronPrimitive.Body = {
            args, location in
            let result = try body()
            return result.myronValue
        }
        let primitive = try primitivise(name: name, arity: .exactly(0), wrapped: wrapped)
        environment.insert(name, value: .primitive(primitive))
    }
    
    public func define(
        _ name: String,
        body: @escaping @Sendable (MyronValue) throws -> MyronValueRepresentable
    ) throws {
        let wrapped: MyronPrimitive.Body = {
            args, location in
            let result = try body(args[0])
            return result.myronValue
        }
        let primitive = try primitivise(name: name, arity: .exactly(1), wrapped: wrapped)
        environment.insert(name, value: .primitive(primitive))
    }
    
    public func define(
        _ name: String,
        body: @escaping @Sendable (MyronValue, MyronValue) throws -> MyronValueRepresentable
    ) throws {
        let wrapped: MyronPrimitive.Body = {
            args, location in
            let result = try body(args[0], args[1])
            return result.myronValue
        }
        let primitive = try primitivise(name: name, arity: .exactly(2), wrapped: wrapped)
        environment.insert(name, value: .primitive(primitive))
    }
    
    public func define(
        _ name: String,
        body: @escaping @Sendable (MyronValue, MyronValue, MyronValue) throws -> MyronValueRepresentable
    ) throws {
        let wrapped: MyronPrimitive.Body = {
            args, location in
            let result = try body(args[0], args[1], args[2])
            return result.myronValue
        }
        let primitive = try primitivise(name: name, arity: .exactly(3), wrapped: wrapped)
        environment.insert(name, value: .primitive(primitive))
    }
    
    public func define(
        _ name: String,
        body: @escaping @Sendable (MyronValue, MyronValue, MyronValue, MyronValue) throws -> MyronValueRepresentable
    ) throws {
        let wrapped: MyronPrimitive.Body = {
            args, location in
            let result = try body(args[0], args[1], args[2], args[3])
            return result.myronValue
        }
        let primitive = try primitivise(name: name, arity: .exactly(4), wrapped: wrapped)
        environment.insert(name, value: .primitive(primitive))
    }
    
    public func define(
        _ name: String,
        body: @escaping @Sendable (MyronValue, MyronValue, MyronValue, MyronValue, MyronValue) throws -> MyronValueRepresentable
    ) throws {
        let wrapped: MyronPrimitive.Body = {
            args, location in
            let result = try body(args[0], args[1], args[2], args[3], args[4])
            return result.myronValue
        }
        let primitive = try primitivise(name: name, arity: .exactly(5), wrapped: wrapped)
        environment.insert(name, value: .primitive(primitive))
    }
    
    public func define(
        _ name: String,
        body: @escaping @Sendable (MyronValue, MyronValue, MyronValue, MyronValue, MyronValue, MyronValue) throws -> MyronValueRepresentable
    ) throws {
        let wrapped: MyronPrimitive.Body = {
            args, location in
            let result = try body(args[0], args[1], args[2], args[3], args[4], args[5])
            return result.myronValue
        }
        let primitive = try primitivise(name: name, arity: .exactly(6), wrapped: wrapped)
        environment.insert(name, value: .primitive(primitive))
    }
    
    private func primitivise(
        name: String,
        arity: MyronError.IntegerExpectation,
        wrapped: @escaping MyronPrimitive.Body
    ) throws -> MyronPrimitive {
        try Self.validatePrimitiveName(name)
        
        let checked: MyronPrimitive.Body = { args, location in
            try Self.validatePrimitiveArity(args.count, expected: arity, at: location)
            
            do {
                return try wrapped(args, location)
                
            } catch let error as MyronError {
                var trampolineError = error
                if error.location == nil {
                    trampolineError = MyronError(
                        reason: error.reason,
                        location: location,
                        message: error.message)
                }
                
                throw trampolineError
                
            } catch let error as MyronHostError {
                throw MyronError(.hostError(error.description), at: location)
                
            } catch {
                let description = String(describing: error)
                throw MyronError(.hostError(description), at: location)
            }
        }
        
        let primitive = MyronPrimitive(
            id: Counter.next(),
            primitiveName: Self.hostNamespace + name,
            representations: [name],
            body: checked)

        return primitive
    }
    
    private static let hostNamespace = "host."

    private static func validatePrimitiveName(_ name: String) throws {
        let (tokens, errors) = Lexer(input: name, sourceHandle: nil).tokenize()
        guard
            errors.isEmpty,
            tokens.count == 1,
            case .symbol(let symbol) = tokens[0].kind,
            symbol == name,
            !Machine.specialFormNames.contains(name)
        else {
            throw MyronError(.invalidName(name))
        }
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
        return environment.lookup(name)
    }

    public func set(_ name: String, to value: MyronValue) {
        environment.insert(name, value: value)
    }

    public var names: Set<String> {
        return environment.names
    }

}

// MARK: - Error Messages

private extension MyronSession {

    func adornErrorsIfNecessary(_ errors: [MyronError], in expression: String) -> [MyronError] {
        errors.map { error in adornErrorIfNecessary(error, in: expression) }
    }

    func adornErrorIfNecessary(_ error: MyronError, in expression: String) -> MyronError {
        switch configuration.errorStyle {
        case .terse: return error
        case .verbose: return error.withMessage(in: expression)
        }
    }

}
