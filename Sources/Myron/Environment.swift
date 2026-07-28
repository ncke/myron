import Foundation

// MARK: - Environment

public final class Environment {
    private var mappings: [String: Value] = [:]
    private var outer: Environment?
    private weak var registry: EnvironmentRegistry?

    init(outer: Environment? = nil, registry: EnvironmentRegistry) {
        self.outer = outer
        self.registry = registry
        self.registry?.register(self)
    }

    public func shutdown() {
        mappings = [:]
    }

    func insert(_ name: String, value: Value) {
        mappings[name] = value
    }

    func lookup(_ name: String) -> Value? {
        return mappings[name]
            ?? outer?.lookup(name)
            ?? standardLookup(name)
    }

}

// MARK: - Standard Environment

private extension Environment {

    func standardLookup(_ name: String) -> Value? {
        switch name {
        case "pi": return .double(Double.pi)

        case "+": return .primitive(StandardMathematics.add)
        case "-": return .primitive(StandardMathematics.sub)
        case "*": return .primitive(StandardMathematics.mul)
        case "/": return .primitive(StandardMathematics.div)

        default:
            return nil
        }
    }

}

// MARK: - Standard Mathematics

struct StandardMathematics {

    static func add(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Alt(.unexpectedArity) }
        let fst = args[0]

        if case .integer(var sum) = fst {
            for arg in args.dropFirst() {
                if case .integer(let n) = arg {
                    sum += n
                } else {
                    return Alt(.typeMismatch)
                }
            }

            return Alt(.integer(sum))
        }

        if case .double(var sum) = fst {
            for arg in args.dropFirst() {
                if case .double(let n) = arg {
                    sum += n
                } else {
                    return Alt(.typeMismatch)
                }
            }

            return Alt(.double(sum))
        }

        return Alt(.typeMismatch)
    }

    static func sub(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 2 else { return Alt(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        if case .integer(let f) = fst, case .integer(let s) = snd {
            return Alt(.integer(f - s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            return Alt(.double(f - s))
        }

        return Alt(.typeMismatch)
    }

    static func mul(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count >= 2 else { return Alt(.unexpectedArity) }
        let fst = args[0]

        if case .integer(var prod) = fst {
            for arg in args.dropFirst() {
                if case .integer(let n) = arg {
                    prod *= n
                } else {
                    return Alt(.typeMismatch)
                }
            }

            return Alt(.integer(prod))
        }

        if case .double(var prod) = fst {
            for arg in args.dropFirst() {
                if case .double(let n) = arg {
                    prod *= n
                } else {
                    return Alt(.typeMismatch)
                }
            }

            return Alt(.double(prod))
        }

        return Alt(.typeMismatch)
    }

    static func div(args: [Value]) -> Alt<Value, MyronError.Reason> {
        guard args.count == 2 else { return Alt(.unexpectedArity) }
        let fst = args[0]
        let snd = args[1]

        if case .integer(let f) = fst, case .integer(let s) = snd {
            if s == 0 { return Alt(.divisionByZero) }
            return Alt(.integer(f / s))
        }

        if case .double(let f) = fst, case .double(let s) = snd {
            if s == Double.zero { return Alt(.divisionByZero) }
            return Alt(.double(f / s))
        }

        return Alt(.typeMismatch)
    }

}
