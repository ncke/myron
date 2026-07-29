import Foundation

// MARK: - Standard Mathematics

struct StandardMathematics {

    static func add(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Either(.unexpectedArity) }
        let fst = args[0]

        if case .integer(var sum) = fst {
            for arg in args.dropFirst() {
                if case .integer(let n) = arg {
                    sum += n
                } else {
                    return Either(.typeMismatch)
                }
            }

            return Either(.integer(sum))
        }

        if case .double(var sum) = fst {
            for arg in args.dropFirst() {
                if case .double(let n) = arg {
                    sum += n
                } else {
                    return Either(.typeMismatch)
                }
            }

            return Either(.double(sum))
        }

        return Either(.typeMismatch)
    }

    static func sub(args: [Value]) -> Either<Value, MyronError.Reason> {
        if args.count == 1 {
            return negation(args: args)
        }

        guard args.count == 2 else { return Either(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Either(.integer(f - s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Either(.double(f - s))
        }

        return Either(.typeMismatch)
    }

    private static func negation(
        args: [Value]
    ) -> Either<Value, MyronError.Reason> {
        guard args.count == 1 else { return Either(.unexpectedArity) }
        let number = args[0]

        if case .integer(let i) = number {
            return Either(.integer(-i))
        }

        if case .double(let d) = number {
            return Either(.double(-d))
        }

        return Either(.typeMismatch)
    }

    static func mul(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Either(.unexpectedArity) }
        let fst = args[0]

        if case .integer(var prod) = fst {
            for arg in args.dropFirst() {
                if case .integer(let n) = arg {
                    prod *= n
                } else {
                    return Either(.typeMismatch)
                }
            }

            return Either(.integer(prod))
        }

        if case .double(var prod) = fst {
            for arg in args.dropFirst() {
                if case .double(let n) = arg {
                    prod *= n
                } else {
                    return Either(.typeMismatch)
                }
            }

            return Either(.double(prod))
        }

        return Either(.typeMismatch)
    }

    static func div(args: [Value]) -> Either<Value, MyronError.Reason> {
        guard args.count == 2 else { return Either(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        if case .integer(let f) = fst, case .integer(let s) = snd {
            if s == 0 { return Either(.divisionByZero) }
            return Either(.integer(f / s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            if s == Double.zero { return Either(.divisionByZero) }
            return Either(.double(f / s))
        }

        return Either(.typeMismatch)
    }

}

