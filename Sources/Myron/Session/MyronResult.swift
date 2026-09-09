import Foundation

// MARK: - MyronResult

public enum MyronResult {
    case success(Value)
    case failure([MyronError])
    case nothing
}

// MARK: - Result Helper

public extension MyronResult {

    var isFailure: Bool {
        switch self {
        case .failure: return true
        default: return false
        }
    }

}
