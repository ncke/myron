import Foundation

// MARK: - Standard Comparison

struct StandardComparison: StandardModule {
    
    static let primitiveDefinitions: [MyronXPrimitive] = [
        
        MyronXPrimitive(
            primitiveName: "comparison.eq",
            representations: ["eq", "=="],
            signature: [MyronValue.equatableKinds, MyronValue.equatableKinds],
            body: { args, location in
                return try .boolean(compareEq(args, at: location))
            }),
        
        MyronXPrimitive(
            primitiveName: "comparison.neq",
            representations: ["neq", "!="],
            signature: [MyronValue.equatableKinds, MyronValue.equatableKinds],
            body: { args, location in
                return try .boolean(!compareEq(args, at: location))
            }),
        
        MyronXPrimitive(
            primitiveName: "comparison.gt",
            representations: ["gt", ">"],
            signature: [MyronValue.equatableKinds, MyronValue.equatableKinds],
            body: { args, location in
                return try .boolean(compareGt(args, at: location))
            }),
        
        MyronXPrimitive(
            primitiveName: "comparison.gte",
            representations: ["gte", ">="],
            signature: [MyronValue.equatableKinds, MyronValue.equatableKinds],
            body: { args, location in
                let greater = try compareGt(args, at: location)
                if greater { return .boolean(true) }
                let equal = try compareEq(args, at: location)
                return equal ? .boolean(true) : .boolean(false)
            }),
        
        MyronXPrimitive(
            primitiveName: "comparison.lt",
            representations: ["lt", "<"],
            signature: [MyronValue.equatableKinds, MyronValue.equatableKinds],
            body: { args, location in
                let greater = try compareGt(args, at: location)
                if greater { return .boolean(false) }
                let equal = try compareEq(args, at: location)
                return equal ? .boolean(false) : .boolean(true)
            }),
        
        MyronXPrimitive(
            primitiveName: "comparison.lte",
            representations: ["lte", "<="],
            signature: [MyronValue.equatableKinds, MyronValue.equatableKinds],
            body: { args, location in
                let greater = try compareGt(args, at: location)
                if greater { return .boolean(false) }
                return .boolean(true)
            })
        
    ]

}

// MARK: - Helpers

extension StandardComparison {
    
    static func compareEq(
        _ args: [MyronValue],
        at location: MyronLocation?
    ) throws -> Bool {
        let (fst, snd) = try args.unwrap2(location)
        guard fst.isEquatable, snd.isEquatable else {
            throw MyronError(.inequatableTypes, at: location)
        }

        return fst.isEqual(snd)
    }
    
    static func compareGt(
        _ args: [MyronValue],
        at location: MyronLocation?
    ) throws -> Bool {
        let (fst, snd) = try args.unwrap2(location)

        guard fst.kind == snd.kind else {
            throw MyronError(.unexpectedType(snd.kind, [fst.kind]), at: location)
        }

        if let f = fst.asInteger, let s = snd.asInteger { return f > s }
        if let f = fst.asDouble, let s = snd.asDouble { return f > s }
        if let f = fst.asString, let s = snd.asString { return f > s }

        throw MyronError(.incomparableTypes, at: location)
    }
    
}
