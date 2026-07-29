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

        // Comparison.
        case "eq": return .primitive(StandardComparison.eq)
        case "==": return .primitive(StandardComparison.eq)
        case "neq": return .primitive(StandardComparison.neq)
        case "!=": return .primitive(StandardComparison.neq)
        case "gt": return .primitive(StandardComparison.gt)
        case ">": return .primitive(StandardComparison.gt)
        case "gte": return .primitive(StandardComparison.gte)
        case ">=": return .primitive(StandardComparison.gte)
        case "lt": return .primitive(StandardComparison.lt)
        case "<": return .primitive(StandardComparison.lt)
        case "lte": return .primitive(StandardComparison.lte)
        case "<=": return .primitive(StandardComparison.lte)

        // Logic.
        case "and": return .primitive(StandardLogic.and)
        case "or": return .primitive(StandardLogic.or)
        case "not": return .primitive(StandardLogic.not)

        // Mathematics.
        case "pi": return .double(Double.pi)
        case "+": return .primitive(StandardMathematics.add)
        case "-": return .primitive(StandardMathematics.sub)
        case "*": return .primitive(StandardMathematics.mul)
        case "/": return .primitive(StandardMathematics.div)
        case "^": return .primitive(Self.unimplemented)
        case "sqrt": return .primitive(Self.unimplemented)
        case "log": return .primitive(Self.unimplemented)
        case "ln": return .primitive(Self.unimplemented)
        case "sin": return .primitive(Self.unimplemented)
        case "cos": return .primitive(Self.unimplemented)
        case "tan": return .primitive(Self.unimplemented)
        case "asin": return .primitive(Self.unimplemented)
        case "acos": return .primitive(Self.unimplemented)
        case "atan": return .primitive(Self.unimplemented)

        // Lists.
        case "head": return .primitive(StandardLists.head)
        case "tail": return .primitive(StandardLists.tail)
        case "last": return .primitive(StandardLists.last)
        case "take": return .primitive(StandardLists.take)
        case "drop": return .primitive(StandardLists.drop)
        case "length": return .primitive(StandardLists.length)
        case "empty": return .primitive(StandardLists.empty)

        default:
            return nil
        }
    }

    static func unimplemented(args: [Value]) -> Alt<Value, MyronError.Reason> {
        Alt(.unimplementedFeature)
    }

}
