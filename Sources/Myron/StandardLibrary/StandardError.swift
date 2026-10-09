import Foundation

// MARK: - Standard Error

struct StandardError: StandardModule {

    static let primitiveDefinitions: [MyronPrimitive] = [

        MyronPrimitive(
            primitiveName: "error.raise",
            representations: ["raise"],
            signature: "({string})",
            body: { args, location in
                let message = try args.unwrap1(location).unwrapString(location)
                throw MyronError(.raised(message), at: location)
            })

    ]

}
