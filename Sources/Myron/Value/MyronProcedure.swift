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

// MARK: - Higher Order and Probe

public enum MyronHigherOrder {
    case map, filter, reduce
}

public enum MyronHigherProbe {
    case all, any
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

// MARK: - Description

extension MyronHigherOrder: CustomStringConvertible {

    public var description: String {
        switch self {
        case .map: return "map"
        case .filter: return "filter"
        case .reduce: return "reduce"
        }
    }

}

extension MyronHigherProbe: CustomStringConvertible {

    public var description: String {
        switch self {
        case .all: return "all"
        case .any: return "any"
        }
    }
    
}




