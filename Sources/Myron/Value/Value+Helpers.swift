import Foundation

// MARK: - Arguments Unwrapping

extension Collection where Element == Value {

    func mustHaveAtLeast(_ n: Int, _ location: Location?) throws {
        if count < n { throw MyronError(.unexpectedArity(count, .atLeast(n)), at: location) }
    }

    func hasArity(_ n: Int) -> Bool { count == n }

    func unwrap1(_ location: Location?) throws -> Value {
        guard count == 1 else {
            throw MyronError(.unexpectedArity(count, .exactly(1)), at: location)
        }
        return self[startIndex]
    }

    func unwrap1List(_ location: Location?) throws -> [Value] {
        guard count == 1 else {
            throw MyronError(.unexpectedArity(count, .exactly(1)), at: location)
        }
        return try self[startIndex].unwrapList(location)
    }

    func unwrap2(_ location: Location?) throws -> (Value, Value) {
        guard count == 2 else {
            throw MyronError(.unexpectedArity(count, .exactly(2)), at: location)
        }
        return (self[startIndex], self[index(startIndex, offsetBy: 1)])
    }

    func unwrap3(_ location: Location?) throws -> (Value, Value, Value) {
        guard count == 3 else {
            throw MyronError(.unexpectedArity(count, .exactly(3)), at: location)
        }
        let i0 = startIndex
        let i1 = index(startIndex, offsetBy: 1)
        let i2 = index(startIndex, offsetBy: 2)
        
        return (self[i0], self[i1], self[i2])
    }

    func unwrapFirst(_ location: Location?) throws -> Value {
        guard let v = first else {
            throw MyronError(.unexpectedArity(count, .atLeast(1)), at: location)
        }
        return v
    }

    func unwrapSecond(_ location: Location?) throws -> Value {
        guard count > 1 else {
            throw MyronError(.unexpectedArity(count, .atLeast(2)), at: location)
        }
        return self[index(startIndex, offsetBy: 1)]
    }

}

// MARK: - Value Unwrapping

extension Value {

    func unwrapBoolean(_ location: Location?) throws -> Bool {
        guard let b = asBoolean else {
            throw MyronError(.unexpectedType(self.kind, [.boolean]), at: location)
        }
        return b
    }

    func unwrapInteger(_ location: Location?) throws -> Int {
        guard let n = asInteger else {
            throw MyronError(.unexpectedType(self.kind, [.integer]), at: location)
        }
        return n
    }

    func unwrapDouble(_ location: Location?) throws -> Double {
        guard let n = asDouble else {
            throw MyronError(.unexpectedType(self.kind, [.double]), at: location)
        }
        return n
    }

    func unwrapList(_ location: Location?) throws -> [Value] {
        guard let l = asList else {
            throw MyronError(.unexpectedType(self.kind, [.list]), at: location)
        }
        return l
    }

    func unwrapString(_ location: Location?) throws -> String {
        guard let s = asString else {
            throw MyronError(.unexpectedType(self.kind, [.string]), at: location)
        }
        return s
    }

    func unwrapSymbol(_ location: Location?) throws -> String {
        guard let s = asSymbol else {
            throw MyronError(.unexpectedType(self.kind, [.symbol]), at: location)
        }
        return s
    }

}

// MARK: - Value Probing

extension Value {

    var isNothing: Bool {
        if case .nothing = self { return true }
        return false
    }

    var isCallable: Bool {
        switch self {
        case .primitive, .procedure: return true
        default: return false
        }
    }

    var asBoolean: Bool? {
        if case .boolean(let b) = self { return b }
        return nil
    }

    var asInteger: Int? {
        if case .integer(let n) = self { return n }
        return nil
    }

    var asDouble: Double? {
        if case .double(let n) = self { return n }
        return nil
    }

    var asList: [Value]? {
        if case .list(let l) = self { return l }
        return nil
    }

    var asString: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var asSymbol: String? {
        if case .symbol(let s) = self { return s }
        return nil
    }

    var asPrimitive: Primitive? {
        if case .primitive(let p) = self { return p }
        return nil
    }

//    var asProcedure: Procedure? {
//        if case .procedure(let p) = self { return p }
//        return nil
//    }

    var asDefine: String? {
        if case .define(let d) = self { return d }
        return nil
    }

}
