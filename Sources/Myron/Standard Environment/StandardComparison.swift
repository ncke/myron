import Foundation

// MARK: - Standard Comparison

struct StandardComparison {

    static func eq(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 2 else { return Either(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        guard fst.typeName == snd.typeName else {
            return Either(.typeMismatch)
        }

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Either(.boolean(f == s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Either(.boolean(f == s))
        }

        if case .boolean(let f) = fst, case .boolean(let s) = snd {
            return Either(.boolean(f == s))
        }

        if case .string(let f) = fst, case .string(let s) = snd {
            return Either(.boolean(f == s))
        }

        if case .symbol(let f) = fst, case .symbol(let s) = snd {
            return Either(.boolean(f == s))
        }

        if case .list(let f) = fst, case .list(let s) = snd {
            if f.count != s.count { return Either(.boolean(false)) }

            for (ef, es) in zip(f, s) {
                let compare = eq(args: [ef, es])
                if compare.second() != nil { return compare }
                if  let result = compare.first(),
                        case .boolean(let bool) = result,
                        !bool
                {
                    return Either(.boolean(false))
                }
            }

            return Either(.boolean(true))
        }

        return Either(.inequatableTypes)
    }

    static func neq(args: [Value]) -> Either<Value, MyronError.Reason> {
        let compare = eq(args: args)
        if compare.second() != nil { return compare }

        if  let result = compare.first(),
            case .boolean(let bool) = result
        {
            return Either(.boolean(!bool))
        }

        return Either(.internalError)
    }

    static func gt(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 2 else { return Either(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        guard fst.typeName == snd.typeName else {
            return Either(.typeMismatch)
        }

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Either(.boolean(f > s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Either(.boolean(f > s))
        }

        if case .string(let f) = fst, case .string(let s) = snd {
            return Either(.boolean(f > s))
        }

        return Either(.incomparableTypes)
    }

    static func gte(args: [Value]) -> Either<Value, MyronError.Reason> {
        let greater = gt(args: args)
        if greater.second() != nil { return greater }
        if case let .boolean(bool) = greater.first(), bool { return greater }

        let equal = eq(args: args)
        return equal
    }

    static func lt(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 2 else { return Either(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        guard fst.typeName == snd.typeName else {
            return Either(.typeMismatch)
        }

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Either(.boolean(f < s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Either(.boolean(f < s))
        }

        if case .string(let f) = fst, case .string(let s) = snd {
            return Either(.boolean(f < s))
        }

        return Either(.incomparableTypes)
    }

    static func lte(args: [Value]) -> Either<Value, MyronError.Reason> {
        let lesser = lt(args: args)
        if lesser.second() != nil { return lesser }
        if case let .boolean(bool) = lesser.first(), bool { return lesser }

        let equal = eq(args: args)
        return equal
    }

}
