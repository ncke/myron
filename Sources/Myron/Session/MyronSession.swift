import Foundation

// MARK: - MyronSession

public final class MyronSession {
    public let runtime: MyronRuntime
    public let process: MyronProcess

    init(runtime: MyronRuntime) {
        self.runtime = runtime
        self.process = runtime.makeProcess()
    }

    public convenience init(configuration: MyronSessionConfiguration = .standard) {
        let runtime = MyronRuntime(configuration: configuration)
        self.init(runtime: runtime)
    }

    deinit {
        runtime.shutdownProcess(process)
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

    public var hasPendingResult: Bool {
        return runtime.hasPendingResult(for: process)
    }

    public func resume() -> MyronResult {
        defer { runtime.tidyEnvironment(process) }
        return runtime.resume(process)
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

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg0
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg1
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg2
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg3
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg4
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg5
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }
    
    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg6
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        arity: MyronError.IntegerExpectation,
        body: @escaping MyronPrimitive.FnContextArgN
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, arity: arity, body: body)
        try runtime.insert(process, name: name, value: .primitive(primitive), location: nil)
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
