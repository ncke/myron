import Foundation

// MARK: - Standard Logic

struct StandardLogic {

    static let not = MyronXPrimitive(name: "logic.not") { args, location in
        let bool = try args.unwrap1(location).unwrapBoolean(location)
        return .boolean(!bool)
    }

}
