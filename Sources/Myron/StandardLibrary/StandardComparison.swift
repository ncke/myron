import Foundation

// MARK: - Standard Comparison

struct StandardComparison: StandardModule {
    
    static let primitiveDefinitions: [MyronPrimitive] = [
        
        MyronPrimitive(
            primitiveName: "comparison.eq",
            representations: ["eq", "=="],
            body: { args, location in
                return try .boolean(compareEq(args, at: location))
            }),
        
        MyronPrimitive(
            primitiveName: "comparison.neq",
            representations: ["neq", "!="],
            body: { args, location in
                return try .boolean(!compareEq(args, at: location))
            }),
        
        MyronPrimitive(
            primitiveName: "comparison.gt",
            representations: ["gt", ">"],
            body: { args, location in
                return try .boolean(compareGt(args, at: location))
            }),
        
        MyronPrimitive(
            primitiveName: "comparison.gte",
            representations: ["gte", ">="],
            body: { args, location in
                let lesser = try compareLt(args, at: location)
                return .boolean(!lesser)
            }),
        
        MyronPrimitive(
            primitiveName: "comparison.lt",
            representations: ["lt", "<"],
            body: { args, location in
                return try .boolean(compareLt(args, at: location))
            }),
        
        MyronPrimitive(
            primitiveName: "comparison.lte",
            representations: ["lte", "<="],
            body: { args, location in
                let greater = try compareGt(args, at: location)
                return .boolean(!greater)
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
        return fst.isEqual(snd)
    }
    
    static func compareLt(
        _ args: [MyronValue],
        at location: MyronLocation?
    ) throws -> Bool {
        let (fst, snd) = try args.unwrap2(location)

        guard fst.kind == snd.kind else {
            throw MyronError(.unexpectedType(snd.kind, [fst.kind]), at: location)
        }

        if let f = fst.asInteger, let s = snd.asInteger { return f < s }
        if let f = fst.asDouble, let s = snd.asDouble {
            //f       s       comp
            //nnn     nnn     f < s
            //nnn     nan     true
            //nan     nnn     false
            //nan     nan     false
            
            if f.isNaN { return false }
            if s.isNaN { return true }
            return f < s
        }
        if let f = fst.asString, let s = snd.asString { return f < s }

        throw MyronError(.incomparableTypes, at: location)
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
        if let f = fst.asDouble, let s = snd.asDouble {
            if s.isNaN { return false }
            if f.isNaN { return true }
            return f > s
        }
        if let f = fst.asString, let s = snd.asString { return f > s }

        throw MyronError(.incomparableTypes, at: location)
    }
    
}
