import Foundation

// MARK: - Standard Logic

struct StandardLogic {

    static func and(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(2, location)

        for arg in args {
            let bool = try arg.unwrapBoolean(location)
            if !bool { return .boolean(false) }
        }

        return .boolean(true)
    }

    static func or(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(2, location)

        for arg in args {
            let bool = try arg.unwrapBoolean(location)
            if bool { return .boolean(true) }
        }

        return .boolean(false)
    }

    static func not(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let bool = try args.unwrap1(location).unwrapBoolean(location)
        return .boolean(!bool)
    }

}
