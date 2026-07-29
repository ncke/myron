import Foundation

struct StandardLists {

    static func head(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 1 else { return Either(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Either(.typeMismatch)
        }

        guard let head = elements.first else { return Either(.nothing) }
        return Either(head)
    }

    static func tail(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 1 else { return Either(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Either(.typeMismatch)
        }

        let tail = Array(elements.dropFirst())
        return Either(.list(tail))
    }

    static func last(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 1 else { return Either(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Either(.typeMismatch)
        }

        guard let last = elements.last else { return Either(.nothing) }
        return Either(last)
    }

    static func take(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 2 else { return Either(.unexpectedArity) }
        guard
            case let .integer(count) = args[0],
            case let .list(elements) = args[1]
        else {
            return Either(.typeMismatch)
        }

        guard count >= 0 else { return Either(.cannotBeNegative) }

        let take = Array(elements.prefix(count))
        return Either(.list(take))
    }

    static func drop(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 2 else { return Either(.unexpectedArity) }
        guard
            case let .integer(count) = args[0],
            case let .list(elements) = args[1]
        else {
            return Either(.typeMismatch)
        }

        guard count >= 0 else { return Either(.cannotBeNegative) }

        let drop = Array(elements.dropFirst(count))
        return Either(.list(drop))
    }

    static func length(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 1 else { return Either(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Either(.typeMismatch)
        }

        let length = elements.count
        return Either(.integer(length))
    }

    static func empty(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 1 else { return Either(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Either(.typeMismatch)
        }

        return Either(.boolean(elements.isEmpty))
    }

}
