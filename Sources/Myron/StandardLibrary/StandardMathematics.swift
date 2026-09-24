import Foundation

// MARK: - Standard Mathematics

struct StandardMathematics: StandardModule {
    
    // MARK: Arithmetic
    
    static let primitiveDefinitions = [
        
        MyronPrimitive(
            primitiveName: "mathematics.add",
            representations: ["add", "+"],
            body: { args, location in
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

                throw MyronError(.unexpectedType(fst.kind, [.integer, .double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.sub",
            representations: ["sub", "-"],
            body: { args, location in
                if args.hasArity(1) {
                    return try negation(args: args, location: location)
                }

                let (fst, snd) = try args.unwrap2(location)

                if let f = fst.asInteger, let s = snd.asInteger {
                    return .integer(try subOverflow(f, s, at: location))
                }

                if let f = fst.asDouble, let s = snd.asDouble { return .double(f - s) }

                throw MyronError(.unexpectedType(fst.kind, [.integer, .double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.mul",
            representations: ["mul", "*"],
            body: { args, location in
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

                throw MyronError(.unexpectedType(fst.kind, [.integer, .double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.div",
            representations: ["div", "/"],
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)

                if let f = fst.asInteger, let s = snd.asInteger {
                    if s == Int.zero { throw MyronError(.divisionByZero, at: location) }
                    return .integer(try divOverflow(f, s, at: location))
                }

                if let f = fst.asDouble, let s = snd.asDouble {
                    if s == Double.zero { throw MyronError(.divisionByZero, at: location) }
                    return .double(f / s)
                }

                throw MyronError(.unexpectedType(fst.kind, [.integer, .double]), at: location)
        }),
        
        // MARK: Modulo & Remainder
        
        MyronPrimitive(
            primitiveName: "mathematics.mod",
            representations: ["mod", "%"],
            body: { args, location in
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

                let got = fst.kind == .integer ? snd.kind : fst.kind
                throw MyronError(.unexpectedType(got, [.integer]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.rem",
            representations: ["rem"],
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)

                if let f = fst.asInteger, let s = snd.asInteger {
                    if s == Int.zero {
                        throw MyronError(.divisionByZero, at: location)
                    }

                    let remainder = try remainderOverflow(f, s, at: location)
                    return .integer(remainder)
                }

                let got = fst.kind == .integer ? snd.kind : fst.kind
                throw MyronError(.unexpectedType(got, [.integer]), at: location)
        }),
        
        // MARK: Numeric Type Conversion
        
        MyronPrimitive(
            primitiveName: "mathematics.integer",
            representations: ["integer"],
            body: { args, location in
                let arg = try args.unwrap1(location)

                if let d = arg.asDouble {
                    guard let i = Int(exactly: d.rounded(.towardZero)) else {
                        throw MyronError(.invalidNumber, at: location)
                    }

                    return .integer(i)
                }

                if arg.asInteger != nil { return arg }

                if let s = arg.asString?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    if let i = Int(s) { return .integer(i) }

                    guard
                        let d = Double(s),
                        let i = Int(exactly: d.rounded(.towardZero))
                    else {
                        throw MyronError(.invalidNumber, at: location)
                    }

                    return .integer(i)
                }

                throw MyronError(.typeCastFailed(arg.kind, .integer), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.double",
            representations: ["double"],
            body: { args, location in
                let arg = try args.unwrap1(location)

                if let i = arg.asInteger { return .double(Double(i)) }

                if arg.asDouble != nil { return arg }

                if let s = arg.asString?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    guard let d = Double(s) else {
                        throw MyronError(.invalidNumber, at: location)
                    }

                    return .double(d)
                }

                throw MyronError(.typeCastFailed(arg.kind, .double), at: location)
        }),
        
        // MARK: Minimum & Maximum
        
        MyronPrimitive(
            primitiveName: "mathematics.min",
            representations: ["min"],
            body: { args, location in
                try args.mustHaveAtLeast(1, location)

                let fst = try args.unwrapFirst(location)
                let tail = args.dropFirst()

                if var minimum = fst.asInteger {
                    for arg in tail { minimum = min(minimum, try arg.unwrapInteger(location)) }
                    return .integer(minimum)
                }

                if var minimum = fst.asDouble {
                    for arg in tail {
                        let number = try arg.unwrapDouble(location)
                        if number.isNaN { continue }
                        minimum = minimum.isNaN ? number : min(minimum, number)
                    }
                    return .double(minimum)
                }

                throw MyronError(.unexpectedType(fst.kind, [.integer, .double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.max",
            representations: ["max"],
            body: { args, location in
                try args.mustHaveAtLeast(1, location)

                let fst = try args.unwrapFirst(location)
                let tail = args.dropFirst()

                if var maximum = fst.asInteger {
                    for arg in tail { maximum = max(maximum, try arg.unwrapInteger(location)) }
                    return .integer(maximum)
                }

                if var maximum = fst.asDouble {
                    for arg in tail {
                        let number = try arg.unwrapDouble(location)
                        if maximum.isNaN { continue }
                        maximum = number.isNaN ? number : max(maximum, number)
                    }
                    return .double(maximum)
                }

                throw MyronError(.unexpectedType(fst.kind, [.integer, .double]), at: location)
        }),
        
        // MARK: Signs
        
        MyronPrimitive(
            primitiveName: "mathematics.neg",
            representations: ["neg"],
            body: { args, location in
                return try Self.negation(args: args, location: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.abs",
            representations: ["abs"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asInteger {
                    return .integer(n < 0 ? try negateOverflow(n, at: location) : n)
                }
                if let n = number.asDouble { return .double(abs(n)) }
                throw MyronError(.unexpectedType(number.kind, [.integer, .double]), at: location)
        }),
        
        // MARK: Rounding
        
        MyronPrimitive(
            primitiveName: "mathematics.floor",
            representations: ["floor"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(floor(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.ceil",
            representations: ["ceil"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(ceil(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.round",
            representations: ["round"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(round(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        // MARK: Power & Root
        
        MyronPrimitive(
            primitiveName: "mathematics.pow",
            representations: ["pow"],
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)

                if let f = fst.asInteger, let s = snd.asInteger {
                    return .integer(try powOverflow(f, s, at: location))
                }

                if let f = fst.asDouble, let s = snd.asDouble {
                    return .double(pow(f, s))
                }

                throw MyronError(.unexpectedType(fst.kind, [.integer, .double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.sqrt",
            representations: ["sqrt"],
            body: { args, location in
                let number = try args.unwrap1(location)

                if let n = number.asInteger { return .double(sqrt(Double(n))) }
                if let n = number.asDouble { return .double(sqrt(n)) }
                throw MyronError(.unexpectedType(number.kind, [.integer, .double]), at: location)
        }),
        
        // MARK: Logarithms
        
        MyronPrimitive(
            primitiveName: "mathematics.log",
            representations: ["log"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(log10(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.ln",
            representations: ["ln"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(log(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        // MARK: Trigonometry
        
        MyronPrimitive(
            primitiveName: "mathematics.sin",
            representations: ["sin"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(sin(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.cos",
            representations: ["cos"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(cos(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.tan",
            representations: ["tan"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(tan(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.asin",
            representations: ["asin"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(asin(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.acos",
            representations: ["acos"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(acos(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.atan",
            representations: ["atan"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let n = number.asDouble { return .double(atan(n)) }
                throw MyronError(.unexpectedType(number.kind, [.double]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.atan2",
            representations: ["atan2"],
            body: { args, location in
                let (y, x) = try args.unwrap2(location)
                if let y = y.asDouble, let x = x.asDouble { return .double(atan2(y, x)) }

                let got = x.kind == .double ? y.kind : x.kind
                throw MyronError(.unexpectedType(got, [.integer]), at: location)
        }),
        
        // MARK: Angles
        
        MyronPrimitive(
            primitiveName: "mathematics.degs-to-rads",
            representations: ["degs-to-rads"],
            body: { args, location in
                let fst = try args.unwrap1(location)
                if let degs = fst.asDouble { return .double((.pi * degs) / 180.0) }
                if let degs = fst.asInteger { return .double((.pi * Double(degs)) / 180.0) }
                throw MyronError(.unexpectedType(fst.kind, [.double, .integer]), at: location)
        }),
        
        MyronPrimitive(
            primitiveName: "mathematics.rads-to-degs",
            representations: ["rads-to-degs"],
            body: { args, location in
                let fst = try args.unwrap1(location)
                if let rads = fst.asDouble { return .double((180.0 * rads) / .pi) }
                throw MyronError(.unexpectedType(fst.kind, [.double]), at: location)
        })
    ]

}

// MARK: - Helpers

private extension StandardMathematics {
    
    static func negation(
        args: [MyronValue],
        location: MyronLocation?
    ) throws -> MyronValue {
        let number = try args.unwrap1(location)
        if let i = number.asInteger { return .integer(try negateOverflow(i, at: location)) }
        if let d = number.asDouble { return .double(-d) }

        throw MyronError(.unexpectedType(number.kind, [.integer, .double]), at: location)
    }

    static func addOverflow(_ lhs: Int, _ rhs: Int, at location: MyronLocation?) throws -> Int {
        let (result, isOverflow) = lhs.addingReportingOverflow(rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func subOverflow(_ lhs: Int, _ rhs: Int, at location: MyronLocation?) throws -> Int {
        let (result, isOverflow) = lhs.subtractingReportingOverflow(rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func mulOverflow(_ lhs: Int, _ rhs: Int, at location: MyronLocation?) throws -> Int {
        let (result, isOverflow) = lhs.multipliedReportingOverflow(by: rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func divOverflow(_ lhs: Int, _ rhs: Int, at location: MyronLocation?) throws -> Int {
        let (result, isOverflow) = lhs.dividedReportingOverflow(by: rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func remainderOverflow(_ lhs: Int, _ rhs: Int, at location: MyronLocation?) throws -> Int {
        if rhs == -1 { return Int.zero }
        let (result, isOverflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        if isOverflow { throw MyronError(.overflow, at: location) }
        return result
    }

    static func negateOverflow(_ value: Int, at location: MyronLocation?) throws -> Int {
        try subOverflow(Int.zero, value, at: location)
    }

    static func powOverflow(_ base: Int, _ exponent: Int, at location: MyronLocation?) throws -> Int {
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
