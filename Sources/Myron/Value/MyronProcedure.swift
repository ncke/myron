import Foundation

// MARK: - MyronProcedure

public struct MyronProcedure {
    let id: Int
    let parameters: [String]
    let bodies: [Expression]
    let environment: Environment
    
    init(parameters: [String], bodies: [Expression], environment: Environment) {
        self.id = Counter.next()
        self.parameters = parameters
        self.bodies = bodies
        self.environment = environment
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
