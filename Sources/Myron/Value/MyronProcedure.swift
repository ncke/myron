import Foundation

// MARK: - MyronProcedure

public struct MyronProcedure {
    let parameters: [String]
    let bodies: [Expression]
    let environment: Environment
}

// MARK: - Higher Order and Probe

public enum MyronHigherOrder {
    case map, filter, reduce
}

public enum MyronHigherProbe {
    case all, any
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
