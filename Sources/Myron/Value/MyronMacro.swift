import Foundation

// MARK: - MyronMacro

public struct MyronMacro {
    let id: Int
    let name: String
    let parameters: [String]
    let variadicIndex: Int?
    let bodies: [Expression]
    let environment: Environment
    let definitionLocation: MyronLocation?

    init(
        name: String,
        parameters: [String],
        bodies: [Expression],
        environment: Environment,
        location: MyronLocation?
    ) throws {
        self.id = Counter.next()
        self.name = name
        (self.parameters, self.variadicIndex) = try Variadics.parse(from: parameters, at: location)
        self.bodies = bodies
        self.environment = environment
        self.definitionLocation = location
    }

}

// MARK: - Argument Binding

extension MyronMacro {

    func bindArguments(
        _ arguments: ArraySlice<MyronValue>,
        into environment: Environment,
        at location: MyronLocation?
    ) throws {
        try Variadics.bindArguments(
            arguments,
            to: parameters,
            withVariadicIndex: variadicIndex,
            environment: environment,
            at: location)
    }

}

// MARK: - Equatable & Hashable

extension MyronMacro: Equatable, Hashable {

    public static func == (lhs: MyronMacro, rhs: MyronMacro) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
