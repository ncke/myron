import Foundation

// MARK: - Standard Environment

extension Environment {

    func standardLookup(_ name: String) -> Value? {
        switch name {

        // Types
        case "nothing": return .nothing

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
        case "finite?": return .primitive(StandardPredicates.isFinite)
        case "infinite?": return .primitive(StandardPredicates.isInfinite)

        // Logic.
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
        case "explode": return .primitive(StandardStrings.explode)
        case "implode": return .primitive(StandardStrings.implode)
        case "string": return .primitive(StandardStrings.string)
        case "lowercase": return .primitive(StandardStrings.lowercase)
        case "uppercase": return .primitive(StandardStrings.uppercase)
        case "trim": return .primitive(StandardStrings.trim)
        case "lines": return .primitive(StandardStrings.lines)
        case "words": return .primitive(StandardStrings.words)

        // Native Lists.
        case "cons": return .primitive(StandardLists.cons)
        case "list": return .primitive(StandardLists.list)

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
        case "key-index": return .primitive(StandardAlist.keyIndex)

        // Native Hashmap.
        case "make-hashmap": return .primitive(StandardHashmap.makeHashmap)
        case "keys-values": return .primitive(StandardHashmap.keysValues)

        default:
            return nil
        }
    }

    static func unimplemented(args: [Value], location: Location?) throws -> Value {
        throw MyronError(.unimplementedFeature, at: location)
    }

}
