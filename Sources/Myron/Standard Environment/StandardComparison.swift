import Foundation

// MARK: - Standard Comparison

struct StandardComparison {

    static func eq(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 2 else { return Alt(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        guard fst.typeName == snd.typeName else {
            return Alt(.typeMismatch)
        }

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Alt(.boolean(f == s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Alt(.boolean(f == s))
        }

        if case .boolean(let f) = fst, case .boolean(let s) = snd {
            return Alt(.boolean(f == s))
        }

        if case .string(let f) = fst, case .string(let s) = snd {
            return Alt(.boolean(f == s))
        }

        if case .symbol(let f) = fst, case .symbol(let s) = snd {
            return Alt(.boolean(f == s))
        }

        if case .list(let f) = fst, case .list(let s) = snd {
            if f.count != s.count { return Alt(.boolean(false)) }

            for (ef, es) in zip(f, s) {
                let compare = eq(args: [ef, es])
                if compare.second() != nil { return compare }
                if  let result = compare.first(),
                        case .boolean(let bool) = result,
                        !bool
                {
                    return Alt(.boolean(false))
                }
            }

            return Alt(.boolean(true))
        }

        return Alt(.inequatableTypes)
    }

    static func neq(args: [Value]) -> Alt<Value, MyronError.Reason> {
        let compare = eq(args: args)
        if compare.second() != nil { return compare }

        if  let result = compare.first(),
            case .boolean(let bool) = result
        {
            return Alt(.boolean(!bool))
        }

        return Alt(.internalError)
    }

    static func gt(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 2 else { return Alt(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        guard fst.typeName == snd.typeName else {
            return Alt(.typeMismatch)
        }

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Alt(.boolean(f > s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Alt(.boolean(f > s))
        }

        if case .string(let f) = fst, case .string(let s) = snd {
            return Alt(.boolean(f > s))
        }

        return Alt(.incomparableTypes)
    }

    static func gte(args: [Value]) -> Alt<Value, MyronError.Reason> {
        let greater = gt(args: args)
        if greater.second() != nil { return greater }
        if case let .boolean(bool) = greater.first(), bool { return greater }

        let equal = eq(args: args)
        return equal
    }

    static func lt(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 2 else { return Alt(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        guard fst.typeName == snd.typeName else {
            return Alt(.typeMismatch)
        }

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Alt(.boolean(f < s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Alt(.boolean(f < s))
        }

        if case .string(let f) = fst, case .string(let s) = snd {
            return Alt(.boolean(f < s))
        }

        return Alt(.incomparableTypes)
    }

    static func lte(args: [Value]) -> Alt<Value, MyronError.Reason> {
        let lesser = lt(args: args)
        if lesser.second() != nil { return lesser }
        if case let .boolean(bool) = lesser.first(), bool { return lesser }

        let equal = eq(args: args)
        return equal
    }

}
