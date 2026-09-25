import Foundation

// MARK: - Value Unwrapping

extension MyronValue {

    func unwrapBoolean(_ location: MyronLocation?) throws -> Bool {
        guard let b = asBoolean else {
            throw MyronError(.unexpectedType(self.kind, [.boolean]), at: location)
        }
        return b
    }
    
    func unwrapDouble(_ location: MyronLocation?) throws -> Double {
        guard let n = asDouble else {
            throw MyronError(.unexpectedType(self.kind, [.double]), at: location)
        }
        return n
    }
    
    func unwrapElements(_ location: MyronLocation?) throws -> [MyronValue] {
        switch self {
        case .list(let elements): return elements
        case .set(let set): return Array(set.contents)
        default: throw MyronError(.unexpectedType(self.kind, [.list, .set]), at: location)
        }
    }

    func unwrapInteger(_ location: MyronLocation?) throws -> Int {
        guard let n = asInteger else {
            throw MyronError(.unexpectedType(self.kind, [.integer]), at: location)
        }
        return n
    }

    func unwrapHashmap(_ location: MyronLocation?) throws -> MyronHashmap {
        guard let h = asHashmap else {
            throw MyronError(.unexpectedType(self.kind, [.hashmap]), at: location)
        }
        return h
    }
    
    func unwrapList(_ location: MyronLocation?) throws -> [MyronValue] {
        guard let l = asList else {
            throw MyronError(.unexpectedType(self.kind, [.list]), at: location)
        }
        return l
    }
    
    func unwrapRecord(_ location: MyronLocation?) throws -> MyronRecord {
        guard let r = asRecord else {
            throw MyronError(.unexpectedType(self.kind, [.record]), at: location)
        }
        return r
    }
    
    func unwrapRecordType(_ location: MyronLocation?) throws -> MyronRecordType {
        guard let t = asRecordType else {
            throw MyronError(.unexpectedType(self.kind, [.recordType]), at: location)
        }
        return t
    }
    
    func unwrapForRecordType(_ location: MyronLocation?) throws -> MyronRecordType {
        switch self {
        case .record(let record): return record.type
        case .recordType(let type): return type
        default: throw MyronError(.unexpectedType(self.kind, [.record, .recordType]), at: location)
        }
    }
    
    func unwrapSet(_ location: MyronLocation?) throws -> MyronSet {
        guard let s = asSet else {
            throw MyronError(.unexpectedType(self.kind, [.set]), at: location)
        }
        return s
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
    
    public var asDouble: Double? {
        if case .double(let n) = self { return n }
        return nil
    }

    public var asInteger: Int? {
        if case .integer(let n) = self { return n }
        return nil
    }

    public var asHashmap: MyronHashmap? {
        if case .hashmap(let h) = self { return h }
        return nil
    }
    
    public var asList: [MyronValue]? {
        if case .list(let l) = self { return l }
        return nil
    }
    
    public var asRecord: MyronRecord? {
        if case .record(let record) = self { return record }
        return nil
    }
    
    public var asRecordType: MyronRecordType? {
        if case .recordType(let recordType) = self { return recordType }
        return nil
    }
    
    public var asSet: MyronSet? {
        if case .set(let s) = self { return s}
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

    var isStorableKey: Bool {
        return flat.first { element in
            guard case .double(let number) = element else { return false }
            return number.isNaN
        } == nil
    }

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

// MARK: - Name Validation

extension MyronValue {
    
    static func validateAsName(_ name: String, location: MyronLocation?) throws {
        if !isValidAsName(name) {
            throw MyronError(.invalidName(name), at: location)
        }
    }
    
    static func isValidAsName(_ name: String) -> Bool {
        let (tokens, errors) = Lexer(input: name, sourceHandle: nil).tokenize()
        guard
            errors.isEmpty,
            tokens.count == 1,
            case .symbol(let symbol) = tokens[0].kind,
            symbol == name,
            !Machine.specialFormNames.contains(name)
        else {
            return false
        }
        
        return true
    }
    
}

// MARK: - Flat

extension MyronValue {
    
    var flat: FlatSequence { FlatSequence(base: self) }
    
    struct FlatSequence: Sequence {
        typealias Iterator = MyronValue.FlatIterator
        let base: MyronValue
        func makeIterator() -> MyronValue.FlatIterator { FlatIterator(value: base) }
    }
    
    struct FlatIterator: IteratorProtocol {
        typealias Element = MyronValue
        private var work: [MyronValue]
        
        init(value: MyronValue) {
            self.work = [value]
        }
        
        mutating func next() -> MyronValue? {
            guard let value = work.popLast() else { return nil }
            
            switch value {
            case .list(let elements):
                work.append(contentsOf: elements)
            case .hashmap(let hm):
                let elements = hm.keysValues().flatMap { (k, v) in [k, v] }
                work.append(contentsOf: elements)
            case .record(let record):
                work.append(contentsOf: record.values)
            case .set(let s):
                work.append(contentsOf: s.contents)
            default:
                break
            }
            
            return value
        }
    }
    
}
