import Foundation

// MARK: - Standard Predicates

struct StandardPredicates {

    static func isNothing(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        return .boolean(try args.unwrap1(location).isNothing)
    }

    static func isNumber(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let value = try args.unwrap1(location)
        if value.asInteger != nil { return .boolean(true) }
        if value.asDouble != nil { return .boolean(true) }
        return .boolean(false)
    }

    static func isInteger(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        return .boolean(try args.unwrap1(location).asInteger != nil)
    }

    static func isDouble(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        return .boolean(try args.unwrap1(location).asDouble != nil)
    }

    static func isString(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        return .boolean(try args.unwrap1(location).asString != nil)
    }

    static func isBoolean(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        return .boolean(try args.unwrap1(location).asBoolean != nil)
    }

    static func isList(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        return .boolean(try args.unwrap1(location).asList != nil)
    }

    static func isPositive(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i > 0) }
        if let d = number.asDouble { return .boolean(d > 0) }
        return .boolean(false)
    }

    static func isNegative(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i < 0) }
        if let d = number.asDouble { return .boolean(d < 0) }
        return .boolean(false)
    }

    static func isZero(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i == Int.zero) }
        if let d = number.asDouble { return .boolean(d == Double.zero) }
        return .boolean(false)
    }

    static func isFinite(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let number = try args.unwrap1(location)
        if let d = number.asDouble { return .boolean(d.isFinite) }
        if number.asInteger != nil { return .boolean(true) }
        return .boolean(false)
    }

    static func isInfinite(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let number = try args.unwrap1(location)
        if let d = number.asDouble { return .boolean(d.isInfinite) }
        return .boolean(false)
    }

}
