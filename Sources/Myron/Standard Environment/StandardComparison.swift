import Foundation

// MARK: - Standard Comparison

struct StandardComparison {

    static func eq(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (fst, snd) = try args.unwrap2(location)
        guard fst.isEquatable, snd.isEquatable else {
            throw MyronError(.inequatableTypes, at: location)
        }

        return .boolean(fst.isEqual(snd))
    }

    static func neq(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let compare = try eq(args: args, location: location)
        if let bool = compare.asBoolean { return .boolean(!bool) }

        let message = "'neq' expects \(compare.kind) as a boolean"
        throw MyronError(.internalError(message), at: location)
    }

    static func gt(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (fst, snd) = try args.unwrap2(location)

        guard fst.kind == snd.kind else {
            throw MyronError(.unexpectedType(snd.kind, [fst.kind]), at: location)
        }

        if let f = fst.asInteger, let s = snd.asInteger { return .boolean(f > s) }
        if let f = fst.asDouble, let s = snd.asDouble { return .boolean(f > s) }
        if let f = fst.asString, let s = snd.asString { return .boolean(f > s) }

        throw MyronError(.incomparableTypes, at: location)
    }

    static func gte(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let greater = try gt(args: args, location: location)
        if try greater.unwrapBoolean(location) { return greater }
        let equal = try eq(args: args, location: location)
        return equal
    }

    static func lt(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (fst, snd) = try args.unwrap2(location)

        guard fst.kind == snd.kind else {
            throw MyronError(.unexpectedType(snd.kind, [fst.kind]), at: location)
        }

        if let f = fst.asInteger, let s = snd.asInteger { return .boolean(f < s) }
        if let f = fst.asDouble, let s = snd.asDouble { return .boolean(f < s) }
        if let f = fst.asString, let s = snd.asString { return .boolean(f < s) }

        throw MyronError(.incomparableTypes, at: location)
    }

    static func lte(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let lesser = try lt(args: args, location: location)
        if try lesser.unwrapBoolean(location) { return lesser }
        let equal = try eq(args: args, location: location)
        return equal
    }

}
