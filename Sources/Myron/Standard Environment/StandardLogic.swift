import Foundation

// MARK: - Standard Logic

struct StandardLogic {

    static func and(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Either(.unexpectedArity) }

        for arg in args {
            if case .boolean(let bool) = arg {
                if !bool { return Either(.boolean(false)) }
            } else {
                return Either(.typeMismatch)
            }
        }

        return Either(.boolean(true))
    }

    static func or(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Either(.unexpectedArity) }

        for arg in args {
            if case .boolean(let bool) = arg {
                if bool { return Either(.boolean(true)) }
            } else {
                return Either(.typeMismatch)
            }
        }

        return Either(.boolean(false))
    }

    static func not(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 1 else { return Either(.unexpectedArity) }

        if case .boolean(let bool) = args[0] {
            return Either(.boolean(!bool))
        }

        return Either(.typeMismatch)
    }
}
