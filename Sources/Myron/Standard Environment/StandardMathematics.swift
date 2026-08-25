import Foundation

// MARK: - Standard Mathematics

struct StandardMathematics {

    static func add(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(2, location)

        let fst = try args.unwrapFirst(location)
        let tail = args.dropFirst()

        if var sum = fst.asInteger {
            for arg in tail { sum += try arg.unwrapInteger(location) }
            return .integer(sum)
        }

        if var sum = fst.asDouble {
            for arg in tail { sum += try arg.unwrapDouble(location) }
            return .double(sum)
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func sub(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        if args.hasArity(1) {
            return try negation(args: args, apply: apply, location: location)
        }

        let (fst, snd) = try args.unwrap2(location)
        if let f = fst.asInteger, let s = snd.asInteger { return .integer(f - s) }
        if let f = fst.asDouble, let s = snd.asDouble { return .double(f - s) }

        throw MyronError(.typeMismatch, at: location)
    }

    private static func negation(
        args: [Value],
        apply: Applier,
        location: Range<Int>?
    ) throws -> Value {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .integer(-i) }
        if let d = number.asDouble { return .double(-d) }

        throw MyronError(.typeMismatch, at: location)
    }

    static func mul(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(2, location)
        let fst = try args.unwrapFirst(location)
        let tail = args.dropFirst()

        if var prod = fst.asInteger {
            for arg in tail { prod *= try arg.unwrapInteger(location) }
            return .integer(prod)
        }

        if var prod = fst.asDouble {
            for arg in tail { prod *= try arg.unwrapDouble(location) }
            return .double(prod)
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func div(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)

        if let f = fst.asInteger, let s = snd.asInteger {
            if s == Int.zero { throw MyronError(.divisionByZero, at: location) }
            return .integer(f / s)
        }

        if let f = fst.asDouble, let s = snd.asDouble {
            if s == Double.zero { throw MyronError(.divisionByZero, at: location) }
            return .double(f / s)
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func squareRoot(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)

        if let n = number.asInteger { return .double(sqrt(Double(n))) }
        if let n = number.asDouble { return .double(sqrt(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

}
