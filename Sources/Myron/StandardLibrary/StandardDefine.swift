import Foundation

// MARK: - Standard Define

struct StandardDefine: StandardModule {

    static let primitiveDefinitions = [

        MyronPrimitive(
            primitiveName: "define.defined-name",
            representations: ["defined-name"],
            signature: "({define})",
            body: { args, location in
                let value = try args.unwrap1(location).unwrapDefine(location)
                return .symbol(value)
        }),

        MyronPrimitive(
            primitiveName: "define.does-define?",
            representations: ["does-define?"],
            signature: "({string symbol} {define})",
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let definedName = try snd.unwrapDefine(location)

                guard let query = fst.asString ?? fst.asSymbol else {
                    throw MyronError(.unexpectedType(fst.kind, [.string, .symbol]), at: location)
                }

                return .boolean(query == definedName)
        })

    ]

}
