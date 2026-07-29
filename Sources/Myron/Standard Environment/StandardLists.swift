import Foundation

struct StandardLists {

    static func head(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 1 else { return Alt(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Alt(.typeMismatch)
        }

        guard let head = elements.first else { return Alt(.nothing) }
        return Alt(head)
    }

    static func tail(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 1 else { return Alt(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Alt(.typeMismatch)
        }

        let tail = Array(elements.dropFirst())
        return Alt(.list(tail))
    }

    static func last(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 1 else { return Alt(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Alt(.typeMismatch)
        }

        guard let last = elements.last else { return Alt(.nothing) }
        return Alt(last)
    }

    static func take(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 2 else { return Alt(.unexpectedArity) }
        guard
            case let .integer(count) = args[0],
            case let .list(elements) = args[1]
        else {
            return Alt(.typeMismatch)
        }

        guard count >= 0 else { return Alt(.cannotBeNegative) }

        let take = Array(elements.prefix(count))
        return Alt(.list(take))
    }

    static func drop(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 2 else { return Alt(.unexpectedArity) }
        guard
            case let .integer(count) = args[0],
            case let .list(elements) = args[1]
        else {
            return Alt(.typeMismatch)
        }

        guard count >= 0 else { return Alt(.cannotBeNegative) }

        let drop = Array(elements.dropFirst(count))
        return Alt(.list(drop))
    }

    static func length(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 1 else { return Alt(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Alt(.typeMismatch)
        }

        let length = elements.count
        return Alt(.integer(length))
    }

    static func empty(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 1 else { return Alt(.unexpectedArity) }
        guard case let .list(elements) = args[0] else {
            return Alt(.typeMismatch)
        }

        return Alt(.boolean(elements.isEmpty))
    }

}
