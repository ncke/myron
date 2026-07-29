import Foundation

// MARK: - Standard Logic

struct StandardLogic {

    static func and(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Alt(.unexpectedArity) }

        for arg in args {
            if case .boolean(let bool) = arg {
                if !bool { return Alt(.boolean(false)) }
            } else {
                return Alt(.typeMismatch)
            }
        }

        return Alt(.boolean(true))
    }

    static func or(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Alt(.unexpectedArity) }

        for arg in args {
            if case .boolean(let bool) = arg {
                if bool { return Alt(.boolean(true)) }
            } else {
                return Alt(.typeMismatch)
            }
        }

        return Alt(.boolean(false))
    }

    static func not(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 1 else { return Alt(.unexpectedArity) }

        if case .boolean(let bool) = args[0] {
            return Alt(.boolean(!bool))
        }

        return Alt(.typeMismatch)
    }
}
