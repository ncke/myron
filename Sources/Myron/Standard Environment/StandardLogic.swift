import Foundation

// MARK: - Standard Logic

struct StandardLogic: StandardModule {
    
    static let primitiveDefinitions = [

        MyronXPrimitive(
            primitiveName: "logic.not",
            representations: ["not"],
            body: { args, location in
                let bool = try args.unwrap1(location).unwrapBoolean(location)
                return .boolean(!bool)
            })
    
    ]

}
