import Foundation

// MARK: - Value Unwrapping

extension MyronValue {

    func unwrapBoolean(_ location: MyronLocation?) throws -> Bool {
        guard let b = asBoolean else {
            throw MyronError(.unexpectedType(self.kind, [.boolean]), at: location)
        }
        return b
    }

    func unwrapDefine(_ location: MyronLocation?) throws -> String {
        guard let d = asDefine else {
            throw MyronError(.unexpectedType(self.kind, [.define]), at: location)
        }
        return d
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

    func unwrapMacro(_ location: MyronLocation?) throws -> MyronMacro {
        guard let m = asMacro else {
            throw MyronError(.unexpectedType(self.kind, [.macro]), at: location)
        }
        return m
    }

    func unwrapModule(_ location: MyronLocation?) throws -> MyronModule {
        guard let m = asModule else {
            throw MyronError(.unexpectedType(self.kind, [.module]), at: location)
        }
        return m
    }

    func unwrapPrimitive(_ location: MyronLocation?) throws -> MyronPrimitive {
        guard let p = asPrimitive else {
            throw MyronError(.unexpectedType(self.kind, [.primitive]), at: location)
        }
        return p
    }

    func unwrapProcedure(_ location: MyronLocation?) throws -> MyronProcedure {
        guard let p = asProcedure else {
            throw MyronError(.unexpectedType(self.kind, [.procedure]), at: location)
        }
        return p
    }

    func unwrapProcess(_ location: MyronLocation?) throws -> MyronProcess {
        guard let p = asProcess else {
            throw MyronError(.unexpectedType(self.kind, [.process]), at: location)
        }
        return p
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

// MARK: - Value Casting

extension MyronValue {

    public var asBoolean: Bool? {
        if case .boolean(let b) = self { return b }
        return nil
    }

    public var asDefine: String? {
        if case .define(let d) = self { return d }
        return nil
    }

    public var asDouble: Double? {
        if case .double(let n) = self { return n }
        return nil
    }

    public var asHashmap: MyronHashmap? {
        if case .hashmap(let h) = self { return h }
        return nil
    }

    public var asInteger: Int? {
        if case .integer(let n) = self { return n }
        return nil
    }

    public var asList: [MyronValue]? {
        if case .list(let l) = self { return l }
        return nil
    }

    public var asMacro: MyronMacro? {
        if case .macro(let m) = self { return m }
        return nil
    }

    public var asModule: MyronModule? {
        if case .module(let m) = self { return m }
        return nil
    }

    public var asPrimitive: MyronPrimitive? {
        if case .primitive(let p) = self { return p }
        return nil
    }

    public var asProcedure: MyronProcedure? {
        if case .procedure(let p) = self { return p }
        return nil
    }

    public var asProcess: MyronProcess? {
        if case .process(let p) = self { return p }
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

// MARK: - Public Value Probing

extension MyronValue {

    public var isBoolean: Bool {
        if case .boolean = self { return true }
        return false
    }

    public var isCallable: Bool {
        switch self {
        case .higherOrder, .higherProbe, .primitive, .procedure: return true
        default: return false
        }
    }

    public var isDefine: Bool {
        if case .define = self { return true }
        return false
    }

    public var isDouble: Bool {
        if case .double = self { return true }
        return false
    }

    public var isHashmap: Bool {
        if case .hashmap = self { return true }
        return false
    }

    public var isInteger: Bool {
        if case .integer = self { return true }
        return false
    }

    public var isNumeric: Bool {
        switch self {
        case .double, .integer: return true
        default: return false
        }
    }

    public var isList: Bool {
        if case .list = self { return true }
        return false
    }

    public var isMacro: Bool {
        if case .macro = self { return true }
        return false
    }

    public var isModule: Bool {
        if case .module = self { return true }
        return false
    }

    public var isNothing: Bool {
        if case .nothing = self { return true }
        return false
    }

    public var isPrimitive: Bool {
        if case .primitive = self { return true }
        return false
    }

    public var isProcedure: Bool {
        if case .procedure = self { return true }
        return false
    }

    public var isProcess: Bool {
        if case .process = self { return true }
        return false
    }

    public var isRecord: Bool {
        if case .record = self { return true }
        return false
    }

    public var isRecordType: Bool {
        if case .recordType = self { return true }
        return false
    }

    public var isSet: Bool {
        if case .set = self { return true }
        return false
    }

    public var isString: Bool {
        if case .string = self { return true }
        return false
    }

    public var isSymbol: Bool {
        if case .symbol = self { return true }
        return false
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

}

// MARK: - Name Validation

extension MyronValue {

    static func validateAsModuleName(_ name: String, location: MyronLocation?) throws {
        try validateAsName(name, location: location)
        guard !name.contains(".") else {
            throw MyronError(.invalidName(name), at: location)
                .withHint(.moduleNamesCannotBeDotted(name))
        }
    }

    static func validateAsModuleExportName(
        _ name: String,
        in moduleName: String,
        location: MyronLocation?
    ) throws {
        try validateAsName(name, location: location)
        guard !name.contains(".") else {
            throw MyronError(.invalidName(name), at: location)
                .withHint(.moduleCannotExportDottedName(moduleName, name))
        }
    }

    static func validateAsSymbolName(
        _ name: String,
        location: MyronLocation?
    ) throws {
        guard isValidAsSymbolName(name) else {
            throw MyronError(.invalidName(name), at: location)
        }
    }

    static func validateAsName(_ name: String, location: MyronLocation?) throws {
        try validateNotEndingInDot(name, location: location)
        if !isValidAsName(name) {
            throw MyronError(.invalidName(name), at: location)
                .withHint(.cannotUseReservedName(name), if: Machine.specialFormNames.contains(name))
        }
    }
    
    private static func validateNotEndingInDot(_ name: String, location: MyronLocation?) throws {
        guard !name.hasSuffix(".") else {
            throw MyronError(.invalidName(name), at: location)
                .withHint(.nameCannotEndInDot(name))
        }
    }

    static func isValidAsSymbolName(_ name: String) -> Bool {
        guard let firstCharacter = name.first else { return false }

        func hasOnlyLegalCharacters() -> Bool {
            !name.contains { ch in
                ch.isWhitespace || ch.isBracket || ch.isSemicolon || ch.isQuotation
            }
        }

        func beginsIllegally() -> Bool {
            return firstCharacter.isDigit
            || firstCharacter.isComma
            || firstCharacter.isQuasiquote
            || firstCharacter.isTick
        }

        func beginsIllegallyWithASign() -> Bool {
            return firstCharacter.isSign && name.count > 1
        }

        return hasOnlyLegalCharacters()
        && !beginsIllegally()
        && !beginsIllegallyWithASign()
        && !Lexer.reservedNames.contains(name)
    }

    static func isValidAsName(_ name: String) -> Bool {
        guard
            isValidAsSymbolName(name),
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
