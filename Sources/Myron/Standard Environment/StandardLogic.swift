import Foundation

// MARK: - Standard Logic

struct StandardLogic {

    static func not(args: [Value], location: Location?) throws -> Value {
        let bool = try args.unwrap1(location).unwrapBoolean(location)
        return .boolean(!bool)
    }

}
