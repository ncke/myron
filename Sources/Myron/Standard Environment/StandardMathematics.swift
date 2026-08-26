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

    static func power(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        
        if let f = fst.asInteger, let s = snd.asInteger {
            return .integer(Int(pow(Double(f), Double(s))))
        }

        if let f = fst.asDouble, let s = snd.asDouble {
            return .double(pow(f, s))
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func mod(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        
        if let f = fst.asInteger, let s = snd.asInteger {
            if s == Int.zero { return fst }
            let quotient = floor(Double(f) / Double(s))
            let remainder = f - s * Int(quotient)
            return .integer(remainder)
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func minimum(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(1, location)

        let fst = try args.unwrapFirst(location)
        let tail = args.dropFirst()

        if var minimum = fst.asInteger {
            for arg in tail { minimum = min(minimum, try arg.unwrapInteger(location)) }
            return .integer(minimum)
        }
        
        if var minimum = fst.asDouble {
            for arg in tail { minimum = min(minimum, try arg.unwrapDouble(location)) }
            return .double(minimum)
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func maximum(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(1, location)

        let fst = try args.unwrapFirst(location)
        let tail = args.dropFirst()

        if var maximum = fst.asInteger {
            for arg in tail { maximum = max(maximum, try arg.unwrapInteger(location)) }
            return .integer(maximum)
        }

        if var maximum = fst.asDouble {
            for arg in tail { maximum = max(maximum, try arg.unwrapDouble(location)) }
            return .double(maximum)
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func floored(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(floor(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func ceilinged(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(ceil(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func rounded(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(round(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func absolute(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asInteger { return .integer(abs(n)) }
        if let n = number.asDouble { return .double(abs(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func squareRoot(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)

        if let n = number.asInteger { return .double(sqrt(Double(n))) }
        if let n = number.asDouble { return .double(sqrt(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func logged(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(log10(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func lned(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(log(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func trigSin(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(sin(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func trigCos(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(cos(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func trigTan(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(tan(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func trigAsin(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(asin(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func trigAcos(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(acos(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func trigAtan(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asDouble { return .double(atan(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

    static func trigAtan2(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (y, x) = try args.unwrap2(location)
        if let y = y.asDouble, let x = x.asDouble { return .double(atan2(y, x)) }
        throw MyronError(.typeMismatch, at: location)
    }

}
