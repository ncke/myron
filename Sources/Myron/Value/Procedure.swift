import Foundation

// MARK: - Procedure

public struct Procedure {
    let parameters: [String]
    let bodies: [Expression]
    let environment: Environment
}

// MARK: - Higher Order and Probe

public enum HigherOrder {
    case map, filter, reduce
}

public enum HigherProbe {
    case all, any
}

extension HigherOrder: CustomStringConvertible {

    public var description: String {
        switch self {
        case .map: return "map"
        case .filter: return "filter"
        case .reduce: return "reduce"
        }
    }

}

extension HigherProbe: CustomStringConvertible {

    public var description: String {
        switch self {
        case .all: return "all"
        case .any: return "any"
        }
    }
}
