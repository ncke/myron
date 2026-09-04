import Foundation

// MARK: - Standard Mathematics

// MARK: - Arithmetic

struct StandardMathematics {

    static func add(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(2, location)

        let fst = try args.unwrapFirst(location)
        let tail = args.dropFirst()

        if var sum = fst.asInteger {
            for arg in tail {
                let num = try arg.unwrapInteger(location)
                sum = try addOverflow(sum, num, at: location)
            }
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

        if let f = fst.asInteger, let s = snd.asInteger {
            return .integer(try subOverflow(f, s, at: location))
        }

        if let f = fst.asDouble, let s = snd.asDouble { return .double(f - s) }

        throw MyronError(.typeMismatch, at: location)
    }

    static func mul(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        try args.mustHaveAtLeast(2, location)
        let fst = try args.unwrapFirst(location)
        let tail = args.dropFirst()

        if var prod = fst.asInteger {
            for arg in tail {
                let num = try arg.unwrapInteger(location)
                prod = try mulOverflow(prod, num, at: location)
            }

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
            return .integer(try divOverflow(f, s, at: location))
        }

        if let f = fst.asDouble, let s = snd.asDouble {
            if s == Double.zero { throw MyronError(.divisionByZero, at: location) }
            return .double(f / s)
        }

        throw MyronError(.typeMismatch, at: location)
    }

}

// MARK: - Modulo and Remainder

extension StandardMathematics {

    static func mod(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)

        if let f = fst.asInteger, let s = snd.asInteger {
            if s == Int.zero {
                throw MyronError(.divisionByZero, at: location)
            }

            var remainder = try remainderOverflow(f, s, at: location)
            if remainder != Int.zero, (remainder < 0) != (s < 0) {
                remainder += s
            }

            return .integer(remainder)
        }

        throw MyronError(.typeMismatch, at: location)
    }

    static func rem(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)

        if let f = fst.asInteger, let s = snd.asInteger {
            if s == Int.zero {
                throw MyronError(.divisionByZero, at: location)
            }

            let remainder = try remainderOverflow(f, s, at: location)
            return .integer(remainder)
        }

        throw MyronError(.typeMismatch, at: location)
    }

}

// MARK: - Numeric Type Conversion

extension StandardMathematics {

    static func castToInteger(
        args: [Value],
        apply: Applier,
        location: Range<Int>?
    ) throws -> Value {
        let arg = try args.unwrap1(location)

        if let d = arg.asDouble {
            guard let i = Int(exactly: d.rounded(.towardZero)) else {
                throw MyronError(.invalidNumber, at: location)
            }

            return .integer(i)
        }

        if arg.asInteger != nil { return arg }

        throw MyronError(.typeMismatch, at: location)
    }

    static func castToDouble(
        args: [Value],
        apply: Applier,
        location: Range<Int>?
    ) throws -> Value {
        let arg = try args.unwrap1(location)

        if let i = arg.asInteger { return .double(Double(i)) }
        if arg.asDouble != nil { return arg }

        throw MyronError(.typeMismatch, at: location)
    }

}


// MARK: - Minimum and Maxiumum

extension StandardMathematics {

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

}

// MARK: - Signs

extension StandardMathematics {

    private static func negation(
        args: [Value],
        apply: Applier,
        location: Range<Int>?
    ) throws -> Value {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .integer(try negateOverflow(i, at: location)) }
        if let d = number.asDouble { return .double(-d) }

        throw MyronError(.typeMismatch, at: location)
    }

    static func absolute(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let number = try args.unwrap1(location)
        if let n = number.asInteger {
            return .integer(n < 0 ? try negateOverflow(n, at: location) : n)
        }
        if let n = number.asDouble { return .double(abs(n)) }
        throw MyronError(.typeMismatch, at: location)
    }

}

// MARK: - Rounding

extension StandardMathematics {

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

}

// MARK: - Power and Root

extension StandardMathematics {

    static func power(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)

        if let f = fst.asInteger, let s = snd.asInteger {
            return .integer(try powOverflow(f, s, at: location))
        }

        if let f = fst.asDouble, let s = snd.asDouble {
            return .double(pow(f, s))
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

// MARK: - Logarithms

extension StandardMathematics {

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

}

// MARK: - Trigonometry

extension StandardMathematics {

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

// MARK: - Overflow Helpers

private extension StandardMathematics {

    static func addOverflow(_ lhs: Int, _ rhs: Int, at location: Range<Int>?) throws -> Int {
        let (result, isOverflow) = lhs.addingReportingOverflow(rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func subOverflow(_ lhs: Int, _ rhs: Int, at location: Range<Int>?) throws -> Int {
        let (result, isOverflow) = lhs.subtractingReportingOverflow(rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func mulOverflow(_ lhs: Int, _ rhs: Int, at location: Range<Int>?) throws -> Int {
        let (result, isOverflow) = lhs.multipliedReportingOverflow(by: rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func divOverflow(_ lhs: Int, _ rhs: Int, at location: Range<Int>?) throws -> Int {
        let (result, isOverflow) = lhs.dividedReportingOverflow(by: rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func remainderOverflow(_ lhs: Int, _ rhs: Int, at location: Range<Int>?) throws -> Int {
        if rhs == -1 { return Int.zero }
        let (result, isOverflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func negateOverflow(_ value: Int, at location: Range<Int>?) throws -> Int {
        try subOverflow(Int.zero, value, at: location)
    }

    static func powOverflow(_ base: Int, _ exponent: Int, at location: Range<Int>?) throws -> Int {
        if exponent < 0 {
            switch base {
            case 0: throw MyronError(.divisionByZero, at: location)
            case 1: return 1
            case -1: return exponent.isMultiple(of: 2) ? 1 : -1
            default: return 0
            }
        }

        var result = 1
        var square = base
        var remaining = exponent
        while remaining > 0 {
            if remaining & 1 == 1 { result = try mulOverflow(result, square, at: location) }
            remaining >>= 1
            if remaining > 0 { square = try mulOverflow(square, square, at: location) }
        }

        return result
    }

}
