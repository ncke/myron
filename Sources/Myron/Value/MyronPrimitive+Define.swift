import Foundation

// MARK: - Function Types

extension MyronPrimitive {

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

}

// MARK: - Define

extension MyronPrimitive {

    static func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg0
    ) throws -> MyronPrimitive {
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

        return primitive
    }

    static func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg1
    ) throws -> MyronPrimitive {
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

        return primitive
    }

    static func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg2
    ) throws -> MyronPrimitive {
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

        return primitive
    }

    static func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg3
    ) throws -> MyronPrimitive {
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

        return primitive
    }

    static func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg4
    ) throws -> MyronPrimitive {
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

        return primitive
    }

    static func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg5
    ) throws -> MyronPrimitive {
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

        return primitive
    }

    static func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping FnContextArg6
    ) throws -> MyronPrimitive {
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

        return primitive
    }

    static func define(
        _ name: String,
        _ signature: String? = nil,
        arity: MyronError.IntegerExpectation,
        body: @escaping FnContextArgN
    ) throws -> MyronPrimitive {
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

        return primitive
    }


}

// MARK: - Primitivise

extension MyronPrimitive {

    private static func primitivise(
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
