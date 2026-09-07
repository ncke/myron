import Foundation

// MARK: - Standard Predicates

struct StandardPredicates {

    static func isNothing(args: [Value], location: Location?) throws -> Value {
        return .boolean(try args.unwrap1(location).isNothing)
    }

    static func isNumber(args: [Value], location: Location?) throws -> Value {
        let value = try args.unwrap1(location)
        if value.asInteger != nil { return .boolean(true) }
        if value.asDouble != nil { return .boolean(true) }
        return .boolean(false)
    }

    static func isInteger(args: [Value], location: Location?) throws -> Value {
        return .boolean(try args.unwrap1(location).asInteger != nil)
    }

    static func isDouble(args: [Value], location: Location?) throws -> Value {
        return .boolean(try args.unwrap1(location).asDouble != nil)
    }

    static func isString(args: [Value], location: Location?) throws -> Value {
        return .boolean(try args.unwrap1(location).asString != nil)
    }

    static func isBoolean(args: [Value], location: Location?) throws -> Value {
        return .boolean(try args.unwrap1(location).asBoolean != nil)
    }

    static func isList(args: [Value], location: Location?) throws -> Value {
        return .boolean(try args.unwrap1(location).asList != nil)
    }

    static func isPositive(args: [Value], location: Location?) throws -> Value {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i > 0) }
        if let d = number.asDouble { return .boolean(d > 0) }
        return .boolean(false)
    }

    static func isNegative(args: [Value], location: Location?) throws -> Value {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i < 0) }
        if let d = number.asDouble { return .boolean(d < 0) }
        return .boolean(false)
    }

    static func isZero(args: [Value], location: Location?) throws -> Value {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .boolean(i == Int.zero) }
        if let d = number.asDouble { return .boolean(d == Double.zero) }
        return .boolean(false)
    }

}
