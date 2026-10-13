import Foundation

// MARK: - Variadic Parameter Parsing

struct Variadics {

    static func parse(
        from parameters: [String],
        at location: MyronLocation?
    ) throws -> ([String], Int?) {
        var slice = ArraySlice(parameters)
        guard let idx = Self.indexOfVariadicParameter(in: slice) else {
            try validateNames(parameters, at: location)
            return (parameters, nil)
        }

        let amended = Self.removeVariadicAnnotation(from: slice[idx])
        guard !amended.isEmpty else {
            let reason = MyronError.Reason.unexpectedVariadicParameter(slice[idx])
            throw MyronError(reason, at: location).withHint(.bareVariadicEncountered)
        }

        slice[idx] = amended

        if let another = Self.indexOfVariadicParameter(in: slice[(idx + 1)...]) {
            let reason = MyronError.Reason.unexpectedVariadicParameter(slice[another])
            throw MyronError(reason, at: location).withHint(.tooManyVariadics)
        }

        let parsed = Array(slice)
        try validateNames(parsed, at: location)
        return (parsed, idx)
    }

    private static func indexOfVariadicParameter(
        in slice: ArraySlice<String>
    ) -> ArraySlice.Index? {
        return slice.firstIndex { name in name.hasSuffix("...") }
    }

    private static func removeVariadicAnnotation(from string: String) -> String {
        return String(string.dropLast(3))
    }

    private static func validateNames(
        _ names: [String],
        at location: MyronLocation?
    ) throws {
        var nameSet = Set<String>()
        for name in names {
            try MyronValue.validateAsName(name, location: location)

            guard !nameSet.contains(name) else {
                throw MyronError(.duplicateName(name), at: location)
                    .withHint(.parameterNamesMustBeUnique)
            }

            nameSet.insert(name)
        }
    }

}

// MARK: - Variadic Argument Binding

extension Variadics {

    struct VariadicBinding<T> {
        let name: String
        let binding: ArraySlice<T>
        let isVariadic: Bool
    }

    static func bindArguments(
        _ arguments: ArraySlice<MyronValue>,
        to parameters: [String],
        withVariadicIndex variadicIndex: Int?,
        environment: Environment,
        at location: MyronLocation?
    ) throws {
        let bindings = try Variadics.bindArguments(
            arguments,
            to: parameters,
            withVariadicIndex: variadicIndex, at: location)

        for binding in bindings {
            if binding.isVariadic {
                let value = MyronValue.list(Array(binding.binding))
                try environment.insert(binding.name, value: value, location: location)
            } else {
                guard binding.binding.count == 1, let value = binding.binding.first else {
                    let explain = "Procedure binding encountered non-single non-variadic"
                    throw MyronError(.internal(explain), at: location)
                }
                try environment.insert(binding.name, value: value, location: location)
            }
        }
    }

    static func bindArguments<T>(
        _ arguments: ArraySlice<T>,
        to parameters: [String],
        withVariadicIndex variadicIndex: Int?,
        at location: MyronLocation?
    ) throws -> [VariadicBinding<T>] {
        if variadicIndex == nil, arguments.count != parameters.count {
            let got = arguments.count
            let expected = parameters.count
            let reason = MyronError.Reason.unexpectedArity(got, .exactly(expected))
            throw MyronError(reason, at: location)
        }

        if variadicIndex != nil, arguments.count < (parameters.count - 1) {
            let got = arguments.count
            let expected = parameters.count - 1
            let reason = MyronError.Reason.unexpectedArity(got, .atLeast(expected))
            throw MyronError(reason, at: location)
        }

        var cursor = arguments.startIndex
        var bindings = [VariadicBinding<T>]()
        for (parameterIdx, parameterName) in parameters.enumerated() {
            if parameterIdx == variadicIndex {
                let restCount = arguments.count - (parameters.count - 1)
                let restEnd = arguments.index(cursor, offsetBy: restCount)
                let binding = VariadicBinding(
                    name: parameterName,
                    binding: arguments[cursor..<restEnd],
                    isVariadic: true)
                bindings.append(binding)
                cursor = restEnd
            } else {
                let binding = VariadicBinding(
                    name: parameterName,
                    binding: arguments[cursor...cursor],
                    isVariadic: false)
                bindings.append(binding)
                cursor = arguments.index(after: cursor)
            }
        }

        return bindings
    }

}
