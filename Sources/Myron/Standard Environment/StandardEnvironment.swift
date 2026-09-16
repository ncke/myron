import Foundation

// MARK: - Standard Environment

extension Environment {

    func standardLookup(_ name: String) -> MyronValue? {
        switch name {

        // Types
        case "nothing": return .nothing

        // Comparison.
        case "eq": return .xprimitive(StandardComparison.eq)
        case "==": return .xprimitive(StandardComparison.eq)
        case "neq": return .xprimitive(StandardComparison.neq)
        case "!=": return .xprimitive(StandardComparison.neq)
        case "gt": return .xprimitive(StandardComparison.gt)
        case ">": return .xprimitive(StandardComparison.gt)
        case "gte": return .xprimitive(StandardComparison.gte)
        case ">=": return .xprimitive(StandardComparison.gte)
        case "lt": return .xprimitive(StandardComparison.lt)
        case "<": return .xprimitive(StandardComparison.lt)
        case "lte": return .xprimitive(StandardComparison.lte)
        case "<=": return .xprimitive(StandardComparison.lte)

        // Predicates.
        case "nothing?": return .xprimitive(StandardPredicates.isNothing)
        case "number?": return .xprimitive(StandardPredicates.isNumber)
        case "integer?": return .xprimitive(StandardPredicates.isInteger)
        case "double?": return .xprimitive(StandardPredicates.isDouble)
        case "string?": return .xprimitive(StandardPredicates.isString)
        case "boolean?": return .xprimitive(StandardPredicates.isBoolean)
        case "list?": return .xprimitive(StandardPredicates.isList)
        case "positive?": return .xprimitive(StandardPredicates.isPositive)
        case "negative?": return .xprimitive(StandardPredicates.isNegative)
        case "zero?": return .xprimitive(StandardPredicates.isZero)
        case "finite?": return .xprimitive(StandardPredicates.isFinite)
        case "infinite?": return .xprimitive(StandardPredicates.isInfinite)
        case "equatable?": return .xprimitive(StandardPredicates.isEquatable)

        // Logic.
        case "not": return .xprimitive(StandardLogic.not)

        // Mathematics.
        case "pi": return .double(Double.pi)
        case "+": return .xprimitive(StandardMathematics.add)
        case "-": return .xprimitive(StandardMathematics.sub)
        case "*": return .xprimitive(StandardMathematics.mul)
        case "/": return .xprimitive(StandardMathematics.div)
        case "pow": return .xprimitive(StandardMathematics.power)
        case "mod": return .xprimitive(StandardMathematics.mod)
        case "rem": return .xprimitive(StandardMathematics.rem)
        case "min": return .xprimitive(StandardMathematics.minimum)
        case "max": return .xprimitive(StandardMathematics.maximum)
        case "floor": return .xprimitive(StandardMathematics.floored)
        case "ceil": return .xprimitive(StandardMathematics.ceilinged)
        case "round": return .xprimitive(StandardMathematics.rounded)
        case "abs": return .xprimitive(StandardMathematics.absolute)
        case "sqrt": return .xprimitive(StandardMathematics.squareRoot)
        case "log": return .xprimitive(StandardMathematics.logged)
        case "ln": return .xprimitive(StandardMathematics.lned)
        case "sin": return .xprimitive(StandardMathematics.trigSin)
        case "cos": return .xprimitive(StandardMathematics.trigCos)
        case "tan": return .xprimitive(StandardMathematics.trigTan)
        case "asin": return .xprimitive(StandardMathematics.trigAsin)
        case "acos": return .xprimitive(StandardMathematics.trigAcos)
        case "atan": return .xprimitive(StandardMathematics.trigAtan)
        case "atan2": return .xprimitive(StandardMathematics.trigAtan2)
        case "integer": return .xprimitive(StandardMathematics.integerCast)
        case "double": return .xprimitive(StandardMathematics.doubleCast)

        // Sequences.
        case "head": return .primitive(StandardSequence.head)
        case "tail": return .primitive(StandardSequence.tail)
        case "init": return .primitive(StandardSequence.initial)
        case "last": return .primitive(StandardSequence.last)
        case "take": return .primitive(StandardSequence.take)
        case "drop": return .primitive(StandardSequence.drop)
        case "length": return .primitive(StandardSequence.length)
        case "empty?": return .primitive(StandardSequence.empty)
        case "append": return .primitive(StandardSequence.append)
        case "reverse": return .primitive(StandardSequence.reverse)
        case "nth": return .primitive(StandardSequence.nth)
        case "contains": return .primitive(StandardSequence.contains)

        // Native String.
        case "explode": return .xprimitive(StandardStrings.explode)
        case "implode": return .xprimitive(StandardStrings.implode)
        case "string": return .xprimitive(StandardStrings.string)
        case "lowercase": return .xprimitive(StandardStrings.lowercase)
        case "uppercase": return .xprimitive(StandardStrings.uppercase)
        case "trim": return .xprimitive(StandardStrings.trim)
        case "lines": return .xprimitive(StandardStrings.lines)
        case "words": return .xprimitive(StandardStrings.words)

        // Native Lists.
        case "cons": return .xprimitive(StandardLists.cons)
        case "list": return .xprimitive(StandardLists.list)

        // Higher-order lists.
        case "map": return .higherOrder(.map)
        case "filter": return .higherOrder(.filter)
        case "reduce": return .higherOrder(.reduce)
        case "all": return .higherProbe(.all)
        case "any": return .higherProbe(.any)

        // Associations.
        case "get": return .primitive(StandardAssociative.get)
        case "get-or": return .primitive(StandardAssociative.getOr)
        case "put": return .primitive(StandardAssociative.put)
        case "remove": return .primitive(StandardAssociative.remove)
        case "has-key?": return .primitive(StandardAssociative.hasKey)
        case "keys": return .primitive(StandardAssociative.keys)
        case "values": return .primitive(StandardAssociative.values)

        // Native Alist.
        case "key-index": return .xprimitive(StandardAlist.keyIndex)

        // Native Hashmap.
        case "make-hashmap": return .xprimitive(StandardHashmap.makeHashmap)
        case "keys-values": return .xprimitive(StandardHashmap.keysValues)

        default:
            return nil
        }
    }

    static func unimplemented(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        throw MyronError(.unimplementedFeature, at: location)
    }

}
