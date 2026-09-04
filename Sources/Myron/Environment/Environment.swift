import Foundation

// MARK: - Environment

public final class Environment {
    private var mappings: [String: Value] = [:]
    private var outer: Environment?
    private(set) weak var registry: EnvironmentRegistry!

    init(outer: Environment? = nil, registry: EnvironmentRegistry) {
        self.outer = outer
        self.registry = registry
        self.registry?.register(self)
    }

    func shutdown() {
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

        // Predicates.
        case "nothing?": return .primitive(StandardPredicates.isNothing)
        case "number?": return .primitive(StandardPredicates.isNumber)
        case "integer?": return .primitive(StandardPredicates.isInteger)
        case "double?": return .primitive(StandardPredicates.isDouble)
        case "string?": return .primitive(StandardPredicates.isString)
        case "boolean?": return .primitive(StandardPredicates.isBoolean)
        case "list?": return .primitive(StandardPredicates.isList)
        case "positive?": return .primitive(StandardPredicates.isPositive)
        case "negative?": return .primitive(StandardPredicates.isNegative)
        case "zero?": return .primitive(StandardPredicates.isZero)

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
        case "pow": return .primitive(StandardMathematics.power)
        case "mod": return .primitive(StandardMathematics.mod)
        case "rem": return .primitive(StandardMathematics.rem)
        case "min": return .primitive(StandardMathematics.minimum)
        case "max": return .primitive(StandardMathematics.maximum)
        case "floor": return .primitive(StandardMathematics.floored)
        case "ceil": return .primitive(StandardMathematics.ceilinged)
        case "round": return .primitive(StandardMathematics.rounded)
        case "abs": return .primitive(StandardMathematics.absolute)
        case "sqrt": return .primitive(StandardMathematics.squareRoot)
        case "log": return .primitive(StandardMathematics.logged)
        case "ln": return .primitive(StandardMathematics.lned)
        case "sin": return .primitive(StandardMathematics.trigSin)
        case "cos": return .primitive(StandardMathematics.trigCos)
        case "tan": return .primitive(StandardMathematics.trigTan)
        case "asin": return .primitive(StandardMathematics.trigAsin)
        case "acos": return .primitive(StandardMathematics.trigAcos)
        case "atan": return .primitive(StandardMathematics.trigAtan)
        case "atan2": return .primitive(StandardMathematics.trigAtan2)
        case "integer": return .primitive(StandardMathematics.castToInteger)
        case "double": return .primitive(StandardMathematics.castToDouble)

        // Sequences.
        case "length": return .primitive(StandardSequence.length)

        // Lists.
        case "head": return .primitive(StandardLists.head)
        case "tail": return .primitive(StandardLists.tail)
        case "init": return .primitive(StandardLists.initial)
        case "last": return .primitive(StandardLists.last)
        case "take": return .primitive(StandardLists.take)
        case "drop": return .primitive(StandardLists.drop)

        case "empty?": return .primitive(StandardLists.empty)
        case "cons": return .primitive(StandardLists.cons)
        case "list": return .primitive(StandardLists.list)
        case "append": return .primitive(StandardLists.append)
        case "reverse": return .primitive(StandardLists.reverse)
        case "nth": return .primitive(StandardLists.nth)
        case "contains": return .primitive(StandardLists.contains)

        // Higher-order lists.
        case "map": return .primitive(StandardHigherLists.map)
        case "filter": return .primitive(StandardHigherLists.filter)
        case "reduce": return .primitive(StandardHigherLists.reduce)
        case "all": return .primitive(StandardHigherLists.all)
        case "any": return .primitive(StandardHigherLists.any)

        default:
            return nil
        }
    }

    static func unimplemented(
        args: [Value],
        applier: Applier,
        location: Range<Int>?
    ) throws -> Value {
        throw MyronError(.unimplementedFeature, at: location)
    }

}
