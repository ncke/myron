import Foundation

// MARK: - Standard Comparison

struct StandardComparison {
    
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
    
//    private static func compareLt(
//        _ args: [MyronValue],
//        at location: MyronLocation?
//    ) throws -> Bool {
//        let (fst, snd) = try args.unwrap2(location)
//
//        guard fst.kind == snd.kind else {
//            throw MyronError(.unexpectedType(snd.kind, [fst.kind]), at: location)
//        }
//
//        if let f = fst.asInteger, let s = snd.asInteger { return f < s }
//        if let f = fst.asDouble, let s = snd.asDouble { return f < s }
//        if let f = fst.asString, let s = snd.asString { return f < s }
//
//        throw MyronError(.incomparableTypes, at: location)
//    }

    static let eq = MyronXPrimitive(name: "comparison.eq") { args, location in
        return try .boolean(compareEq(args, at: location))
    }

    static let neq = MyronXPrimitive(name: "comparison.neq") { args, location in
        return try .boolean(!compareEq(args, at: location))
    }

    static let gt = MyronXPrimitive(name: "comparison.gt") { args, location in
        return try .boolean(compareGt(args, at: location))
    }

    static let gte = MyronXPrimitive(name: "comparison.gte") { args, location in
        let greater = try compareGt(args, at: location)
        if greater { return .boolean(true) }
        let equal = try compareEq(args, at: location)
        return equal ? .boolean(true) : .boolean(false)
    }

    static let lt = MyronXPrimitive(name: "comparison.lt") { args, location in
        let greater = try compareGt(args, at: location)
        if greater { return .boolean(false) }
        let equal = try compareEq(args, at: location)
        return equal ? .boolean(false) : .boolean(true)
    }

    static let lte = MyronXPrimitive(name: "comparison.lte") { args, location in
        let greater = try compareGt(args, at: location)
        if greater { return .boolean(false) }
        return .boolean(true)
    }

}
