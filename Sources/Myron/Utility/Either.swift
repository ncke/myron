import Foundation

// MARK: - Either

public struct Either<First, Second> {

    private enum Store {
        case first(First)
        case second(Second)
    }

    private let store: Store

    init(_ first: First) {
        self.store = .first(first)
    }
    
    init(_ second: Second) {
        self.store = .second(second)
    }

    func first() -> First? {
        guard case let .first(first) = store else { return nil }
        return first
    }

    func second() -> Second? {
        guard case let .second(second) = store else { return nil }
        return second
    }

}
