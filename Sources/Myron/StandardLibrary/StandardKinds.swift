import Foundation

// MARK: - Standard Kinds

struct StandardKinds: StandardModule {
    
    static let primitiveDefinitions = [

        // MARK: Kind

        MyronPrimitive(
            primitiveName: "kinds.kind",
            representations: ["kind"],
            signature: "({any})",
            body: { args, location in
                let value = try args.unwrap1(location)
                let kind = value.kind
                return .string(kind.description)
            }),

        // MARK: - Make Symbol

        MyronPrimitive(
            primitiveName: "kinds.make-symbol",
            representations: ["make-symbol"],
            signature: "({string})",
            body: { args, location in
                let name = try args.unwrap1(location).unwrapString(location)
                try MyronValue.validateAsSymbolName(name, location: location)
                return .symbol(name)
        })

    ]
}
