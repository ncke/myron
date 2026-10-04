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
        (self.parameters, self.variadicIndex) = try Variadics.parse(from: parameters, at: location)
        self.bodies = bodies
        self.environment = environment
    }
    
}

// MARK: - Argument Binding

extension MyronProcedure {

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

extension MyronProcedure: Equatable, Hashable {
    
    public static func == (lhs: MyronProcedure, rhs: MyronProcedure) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
