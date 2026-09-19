import Foundation

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
        case .map: return "<primitive: higher.map>"
        case .filter: return "<primitive: higher.filter>"
        case .reduce: return "<primitive: higher.reduce>"
        }
    }

}

extension MyronHigherProbe: CustomStringConvertible {

    public var description: String {
        switch self {
        case .all: return "<primitive: higher.all>"
        case .any: return "<primitive: higher.any>"
        }
    }
    
}
