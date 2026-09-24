import Foundation

// MARK: - Standard Kinds

struct StandardKinds: StandardModule {
    
    static let primitiveDefinitions = [
        
        // MARK: Kind
        
        MyronPrimitive(
            primitiveName: "kinds.kind",
            representations: ["kind"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let value = try args.unwrap1(location)
                let kind = value.kind
                return .string(kind.description)
            })
        
    ]
}
