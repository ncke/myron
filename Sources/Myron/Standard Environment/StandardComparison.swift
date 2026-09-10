import Foundation

// MARK: - Standard Comparison

struct StandardComparison {

    static func eq(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        guard fst.kind == snd.kind else { return .boolean(false) }

        if let f = fst.asInteger, let s = snd.asInteger { return .boolean(f == s) }
        if let f = fst.asDouble, let s = snd.asDouble { return .boolean(f == s) }
        if let f = fst.asBoolean, let s = snd.asBoolean { return .boolean(f == s) }
        if let f = fst.asString, let s = snd.asString { return .boolean(f == s) }
        if let f = fst.asSymbol, let s = snd.asSymbol { return .boolean(f == s) }
        if case .nothing = fst { return .boolean(true) }

        if let f = fst.asList, let s = snd.asList {
            if f.count != s.count { return .boolean(false) }

            for (ef, es) in zip(f, s) {
                let compare = try eq(args: [ef, es], location: location)
                if try !compare.unwrapBoolean(location) { return .boolean(false) }
            }

            return .boolean(true)
        }

        throw MyronError(.inequatableTypes, at: location)
    }

    static func neq(args: [Value], location: Location?) throws -> Value {
        let compare = try eq(args: args, location: location)
        if let bool = compare.asBoolean { return .boolean(!bool) }

        let message = "'neq' expects \(compare.kind) as a boolean"
        throw MyronError(.internalError(message), at: location)
    }

    static func gt(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)

        guard fst.kind == snd.kind else {
            throw MyronError(.unexpectedType(snd.kind, [fst.kind]), at: location)
        }

        if let f = fst.asInteger, let s = snd.asInteger { return .boolean(f > s) }
        if let f = fst.asDouble, let s = snd.asDouble { return .boolean(f > s) }
        if let f = fst.asString, let s = snd.asString { return .boolean(f > s) }

        throw MyronError(.incomparableTypes, at: location)
    }

    static func gte(args: [Value], location: Location?) throws -> Value {
        let greater = try gt(args: args, location: location)
        if try greater.unwrapBoolean(location) { return greater }
        let equal = try eq(args: args, location: location)
        return equal
    }

    static func lt(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)

        guard fst.kind == snd.kind else {
            throw MyronError(.unexpectedType(snd.kind, [fst.kind]), at: location)
        }

        if let f = fst.asInteger, let s = snd.asInteger { return .boolean(f < s) }
        if let f = fst.asDouble, let s = snd.asDouble { return .boolean(f < s) }
        if let f = fst.asString, let s = snd.asString { return .boolean(f < s) }

        throw MyronError(.incomparableTypes, at: location)
    }

    static func lte(args: [Value], location: Location?) throws -> Value {
        let lesser = try lt(args: args, location: location)
        if try lesser.unwrapBoolean(location) { return lesser }
        let equal = try eq(args: args, location: location)
        return equal
    }

}
