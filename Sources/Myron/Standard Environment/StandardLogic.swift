import Foundation

// MARK: - Standard Logic

struct StandardLogic {

    static func not(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let bool = try args.unwrap1(location).unwrapBoolean(location)
        return .boolean(!bool)
    }

}
