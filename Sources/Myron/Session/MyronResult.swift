import Foundation

// MARK: - MyronResult

public enum MyronResult {
    case success(MyronValue)
    case failure([MyronError])
    case nothing
}

// MARK: - Result Helpers

extension MyronResult {

    public var isSuccess: Bool {
        switch self {
        case .success: return true
        default: return false
        }
    }

    public var asSuccess: MyronValue? {
        switch self {
        case .success(let value): return value
        default: return nil
        }
    }

    public var isFailure: Bool {
        switch self {
        case .failure: return true
        default: return false
        }
    }

    public var asFailure: [MyronError]? {
        switch self {
        case .failure(let errors): return errors
        default: return nil
        }
    }

    public var isNothing: Bool {
        switch self {
        case .nothing: return true
        default: return false
        }
    }

}
