import Foundation

// MARK: - Standard Predicates

struct StandardPredicates {

    static let isNothing = MyronXPrimitive(name: "comparison.nothing?") { args, location in
        return .boolean(try args.unwrap1(location).isNothing)
    }

    static let isNumber = MyronXPrimitive(name: "comparison.number?") { args, location in
        let value = try args.unwrap1(location)
        if value.asInteger != nil { return .boolean(true) }
        if value.asDouble != nil { return .boolean(true) }
        return .boolean(false)
    }

    static let isInteger = MyronXPrimitive(name: "comparison.integer?") { args, location in
        return .boolean(try args.unwrap1(location).asInteger != nil)
    }

    static let isDouble = MyronXPrimitive(name: "comparison.double?") { args, location in
        return .boolean(try args.unwrap1(location).asDouble != nil)
    }

    static let isString = MyronXPrimitive(name: "comparison.string?") { args, location in
        return .boolean(try args.unwrap1(location).asString != nil)
    }

    static let isBoolean = MyronXPrimitive(name: "comparison.boolean?") { args, location in
        return .boolean(try args.unwrap1(location).asBoolean != nil)
    }

    static let isList = MyronXPrimitive(name: "comparison.list?") { args, location in
        return .boolean(try args.unwrap1(location).asList != nil)
    }

    static let isPositive = MyronXPrimitive(name: "comparison.positive?") { args, location in
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i > 0) }
        if let d = number.asDouble { return .boolean(d > 0) }
        return .boolean(false)
    }

    static let isNegative = MyronXPrimitive(name: "comparison.negative?") { args, location in
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i < 0) }
        if let d = number.asDouble { return .boolean(d < 0) }
        return .boolean(false)
    }

    static let isZero = MyronXPrimitive(name: "comparison.zero?") { args, location in
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i == Int.zero) }
        if let d = number.asDouble { return .boolean(d == Double.zero) }
        return .boolean(false)
    }

    static let isFinite = MyronXPrimitive(name: "comparison.finite?") { args, location in
        let number = try args.unwrap1(location)
        if let d = number.asDouble { return .boolean(d.isFinite) }
        if number.asInteger != nil { return .boolean(true) }
        return .boolean(false)
    }

    static let isInfinite = MyronXPrimitive(name: "comparison.infinite?") { args, location in
        let number = try args.unwrap1(location)
        if let d = number.asDouble { return .boolean(d.isInfinite) }
        return .boolean(false)
    }

    static let isEquatable = MyronXPrimitive(name: "comparison.equatable?") { args, location in
        let value = try args.unwrap1(location)
        return .boolean(value.isEquatable)
    }

    static let isCallable = MyronXPrimitive(name: "comparison.callable?") { args, location in
        let value = try args.unwrap1(location)
        return .boolean(value.isCallable)
    }
    
}
