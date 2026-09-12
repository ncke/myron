import Foundation

// MARK: - Value Unwrapping

extension MyronValue {

    func unwrapBoolean(_ location: MyronLocation?) throws -> Bool {
        guard let b = asBoolean else {
            throw MyronError(.unexpectedType(self.kind, [.boolean]), at: location)
        }
        return b
    }

    func unwrapInteger(_ location: MyronLocation?) throws -> Int {
        guard let n = asInteger else {
            throw MyronError(.unexpectedType(self.kind, [.integer]), at: location)
        }
        return n
    }

    func unwrapDouble(_ location: MyronLocation?) throws -> Double {
        guard let n = asDouble else {
            throw MyronError(.unexpectedType(self.kind, [.double]), at: location)
        }
        return n
    }

    func unwrapList(_ location: MyronLocation?) throws -> [MyronValue] {
        guard let l = asList else {
            throw MyronError(.unexpectedType(self.kind, [.list]), at: location)
        }
        return l
    }

    func unwrapHashmap(_ location: MyronLocation?) throws -> MyronHashmap {
        guard let h = asHashmap else {
            throw MyronError(.unexpectedType(self.kind, [.hashmap]), at: location)
        }
        return h
    }

    func unwrapString(_ location: MyronLocation?) throws -> String {
        guard let s = asString else {
            throw MyronError(.unexpectedType(self.kind, [.string]), at: location)
        }
        return s
    }

    func unwrapSymbol(_ location: MyronLocation?) throws -> String {
        guard let s = asSymbol else {
            throw MyronError(.unexpectedType(self.kind, [.symbol]), at: location)
        }
        return s
    }

}

// MARK: - Public Value Probing

extension MyronValue {

    public var asBoolean: Bool? {
        if case .boolean(let b) = self { return b }
        return nil
    }

    public var asInteger: Int? {
        if case .integer(let n) = self { return n }
        return nil
    }

    public var asDouble: Double? {
        if case .double(let n) = self { return n }
        return nil
    }

    public var asList: [MyronValue]? {
        if case .list(let l) = self { return l }
        return nil
    }

    public var asHashmap: MyronHashmap? {
        if case .hashmap(let h) = self { return h }
        return nil
    }

    public var asString: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    public var asSymbol: String? {
        if case .symbol(let s) = self { return s }
        return nil
    }

}

// MARK: - Internal Value Probing

extension MyronValue {

    var isNothing: Bool {
        if case .nothing = self { return true }
        return false
    }

    var isCallable: Bool {
        switch self {
        case .higherOrder, .higherProbe, .primitive, .procedure: return true
        default: return false
        }
    }

    var asPrimitive: MyronPrimitive? {
        if case .primitive(let p) = self { return p }
        return nil
    }

    var asProcedure: MyronProcedure? {
        if case .procedure(let p) = self { return p }
        return nil
    }

    var asDefine: String? {
        if case .define(let d) = self { return d }
        return nil
    }

}
