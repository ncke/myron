import Foundation

// MARK: - MyronProcedure

public struct MyronProcedure {
    let id: Int
    let parameters: [String]
    let variadicIndex: Int?
    let bodies: [Expression]
    let environment: Environment
    
    init(
        parameters: [String],
        bodies: [Expression],
        environment: Environment,
        location: MyronLocation?
    ) throws {
        self.id = Counter.next()
        (self.parameters, self.variadicIndex) = try Self.parseVariadicParameter(
            in: parameters,
            at: location)
        for parameter in self.parameters {
            try MyronValue.validateNotEndingInDot(parameter, location: location)
        }
        self.bodies = bodies
        self.environment = environment
    }
    
}

// MARK: - Variadic Parameter Parsing

extension MyronProcedure {

    private static func parseVariadicParameter(
        in parameters: [String],
        at location: MyronLocation?
    ) throws -> ([String], Int?) {
        var slice = ArraySlice(parameters)
        guard let idx = indexOfVariadicParameter(in: slice) else { return (parameters, nil) }

        let amended = removeVariadicAnnotation(from: slice[idx])
        guard !amended.isEmpty else {
            let reason = MyronError.Reason.unexpectedVariadicParameter(slice[idx])
            throw MyronError(reason, at: location).withHint(.bareVariadicEncountered)
        }

        slice[idx] = amended

        if let another = indexOfVariadicParameter(in: slice[(idx + 1)...]) {
            let reason = MyronError.Reason.unexpectedVariadicParameter(slice[another])
            throw MyronError(reason, at: location).withHint(.tooManyVariadics)
        }

        return (Array(slice), idx)
    }

    private static func indexOfVariadicParameter(
        in slice: ArraySlice<String>
    ) -> ArraySlice.Index? {
        return slice.firstIndex { name in name.hasSuffix("...") }
    }

    private static func removeVariadicAnnotation(from string: String) -> String {
        return String(string.dropLast(3))
    }

}

// MARK: - Argument Binding

extension MyronProcedure {

    func bindArguments(
        _ arguments: ArraySlice<MyronValue>,
        into environment: Environment,
        at location: MyronLocation?
    ) throws {
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
        for (parameterIdx, parameterName) in parameters.enumerated() {
            if parameterIdx == variadicIndex {
                let restCount = arguments.count - (parameters.count - 1)
                let restEnd = arguments.index(cursor, offsetBy: restCount)
                environment.insert(parameterName, value: .list(Array(arguments[cursor..<restEnd])))
                cursor = restEnd
            } else {
                environment.insert(parameterName, value: arguments[cursor])
                cursor = arguments.index(after: cursor)
            }
        }
    }

}

// MARK: - Equatable & Hashable

extension MyronProcedure: Equatable, Hashable {
    
    public static func == (lhs: MyronProcedure, rhs: MyronProcedure) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
