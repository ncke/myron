import Foundation

// MARK: - Standard Logic

struct StandardLogic {

    static func not(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let bool = try args.unwrap1(location).unwrapBoolean(location)
        return .boolean(!bool)
    }

}
