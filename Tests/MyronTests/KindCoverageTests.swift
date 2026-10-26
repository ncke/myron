import Testing
@testable import Myron

// MARK: - Kind Coverage

// Every kind of value has a Myron predicate and a set of Swift accessors. The
// switches below are exhaustive, so a new kind does not compile until it says
// how it is covered, and the tests then check that the coverage it claims is
// there and that it answers for that kind alone.

@Suite("Kind Coverage")

struct KindCoverageTests {

    typealias Kind = MyronValue.Kind

    // MARK: Samples

    // A value of the kind is the last form of setup followed by expression.
    private static func sampleSource(_ kind: Kind) -> (setup: String, expression: String) {
        switch kind {
        case .boolean: ("", "true")
        case .define: ("", "(define x 1)")
        case .double: ("", "1.5")
        case .hashmap: ("", "(make-hashmap)")
        case .higherOrder: ("", "map")
        case .higherProbe: ("", "all")
        case .integer: ("", "1")
        case .list: ("", "'(1)")
        case .macro: ("(defmacro (m x) x)", "m")
        case .module: ("(module m (a) (define a 1))", "m")
        case .nothing: ("", "nothing")
        case .primitive: ("", "sqrt")
        case .procedure: ("", "(lambda (x) x)")
        case .process: ("(module m (go) (define (go) 1))", "(spawn (m) m.go)")
        case .record: ("", "(make-record (make-record-type 'point '(x y)) 1 2)")
        case .recordType: ("", "(make-record-type 'point '(x y))")
        case .set: ("", "(set 1)")
        case .string: ("", "\"a\"")
        case .symbol: ("", "'a")
        }
    }

    private static func sample(_ kind: Kind) throws -> MyronValue {
        let (setup, expression) = sampleSource(kind)
        switch MyronSession().eval(setup + " " + expression) {
        case .success(let value): return value
        case .nothing: return .nothing
        case .failure(let errors):
            Issue.record("the \(kind) sample failed: \(errors.map(\.reason))")
            throw errors[0]
        }
    }

    private static func allSamples() throws -> [MyronValue] {
        try Kind.allCases.map(sample)
    }

    @Test("every sample is of its kind", arguments: Kind.allCases)
    func sampleIsOfItsKind(_ kind: Kind) throws {
        #expect(try Self.sample(kind).kind == kind)
    }

    // MARK: Myron Predicates

    private enum PredicateCoverage: Equatable {
        case predicate(String)
        case callable
    }

    // A program cannot tell the callable kinds apart, so they share callable?.
    private static func predicateCoverage(_ kind: Kind) -> PredicateCoverage {
        switch kind {
        case .boolean: .predicate("boolean?")
        case .define: .predicate("define?")
        case .double: .predicate("double?")
        case .hashmap: .predicate("hashmap?")
        case .higherOrder: .callable
        case .higherProbe: .callable
        case .integer: .predicate("integer?")
        case .list: .predicate("list?")
        case .macro: .predicate("macro?")
        case .module: .predicate("module?")
        case .nothing: .predicate("nothing?")
        case .primitive: .callable
        case .procedure: .callable
        case .process: .predicate("process?")
        case .record: .predicate("record?")
        case .recordType: .predicate("record-type?")
        case .set: .predicate("set?")
        case .string: .predicate("string?")
        case .symbol: .predicate("symbol?")
        }
    }

    @Test("a kind's predicate is named for what kind calls it", arguments: Kind.allCases)
    func predicateIsNamedForTheKind(_ kind: Kind) {
        guard case .predicate(let name) = Self.predicateCoverage(kind) else { return }
        #expect(name == "\(kind.description)?")
    }

    @Test("a kind's predicate holds for that kind alone", arguments: Kind.allCases)
    func predicateHoldsForItsKindAlone(_ kind: Kind) {
        guard case .predicate(let name) = Self.predicateCoverage(kind) else { return }

        for other in Kind.allCases {
            let (setup, expression) = Self.sampleSource(other)
            let expected = other == kind ? "true" : "false"
            expectValue("\(setup) (\(name) \(expression))", expected)
        }
    }

    @Test("callable? holds for the callable kinds alone")
    func callableHoldsForCallableKinds() {
        for kind in Kind.allCases {
            let (setup, expression) = Self.sampleSource(kind)
            let expected = Self.predicateCoverage(kind) == .callable ? "true" : "false"
            expectValue("\(setup) (callable? \(expression))", expected)
        }
    }

    // MARK: Swift Accessors

    // Whether a value answers to a kind's isX, asX and requireX.
    private struct Accessors {
        let probe: (MyronValue) -> Bool
        let cast: ((MyronValue) -> Bool)?
        let require: ((MyronValue) -> Bool)?
    }

    private static func accessors<T>(
        _ probe: @escaping (MyronValue) -> Bool,
        _ cast: @escaping (MyronValue) -> T?,
        _ require: @escaping (MyronValue) throws -> T
    ) -> Accessors {
        Accessors(
            probe: probe,
            cast: { value in cast(value) != nil },
            require: { value in (try? require(value)) != nil })
    }

    // The higher-order primitives are primitives in name only, and answer to
    // isCallable rather than to the primitive accessors.
    private static func accessors(_ kind: Kind) -> Accessors? {
        switch kind {
        case .boolean: accessors(\.isBoolean, \.asBoolean) { v in try v.requireBoolean() }
        case .define: accessors(\.isDefine, \.asDefine) { v in try v.requireDefine() }
        case .double: accessors(\.isDouble, \.asDouble) { v in try v.requireDouble() }
        case .hashmap: accessors(\.isHashmap, \.asHashmap) { v in try v.requireHashmap() }
        case .higherOrder: nil
        case .higherProbe: nil
        case .integer: accessors(\.isInteger, \.asInteger) { v in try v.requireInteger() }
        case .list: accessors(\.isList, \.asList) { v in try v.requireList() }
        case .macro: accessors(\.isMacro, \.asMacro) { v in try v.requireMacro() }
        case .module: accessors(\.isModule, \.asModule) { v in try v.requireModule() }
        case .nothing: Accessors(probe: \.isNothing, cast: nil, require: nil)
        case .primitive: accessors(\.isPrimitive, \.asPrimitive) { v in try v.requirePrimitive() }
        case .procedure: accessors(\.isProcedure, \.asProcedure) { v in try v.requireProcedure() }
        case .process: accessors(\.isProcess, \.asProcess) { v in try v.requireProcess() }
        case .record: accessors(\.isRecord, \.asRecord) { v in try v.requireRecord() }
        case .recordType: accessors(\.isRecordType, \.asRecordType) { v in try v.requireRecordType() }
        case .set: accessors(\.isSet, \.asSet) { v in try v.requireSet() }
        case .string: accessors(\.isString, \.asString) { v in try v.requireString() }
        case .symbol: accessors(\.isSymbol, \.asSymbol) { v in try v.requireSymbol() }
        }
    }

    @Test("a kind's Swift accessors answer for that kind alone", arguments: Kind.allCases)
    func accessorsAnswerForTheirKindAlone(_ kind: Kind) throws {
        guard let accessors = Self.accessors(kind) else { return }

        for value in try Self.allSamples() {
            let expected = value.kind == kind
            #expect(accessors.probe(value) == expected, "is\(kind) on \(value.kind)")
            if let cast = accessors.cast {
                #expect(cast(value) == expected, "as\(kind) on \(value.kind)")
            }
            if let require = accessors.require {
                #expect(require(value) == expected, "require\(kind) on \(value.kind)")
            }
        }
    }

    @Test("isCallable holds for the callable kinds alone")
    func isCallableHoldsForCallableKinds() throws {
        for value in try Self.allSamples() {
            let expected = Self.predicateCoverage(value.kind) == .callable
            #expect(value.isCallable == expected, "isCallable on \(value.kind)")
        }
    }

    @Test("isNumeric holds for integers and doubles alone")
    func isNumericHoldsForNumbers() throws {
        for value in try Self.allSamples() {
            let expected = value.kind == .integer || value.kind == .double
            #expect(value.isNumeric == expected, "isNumeric on \(value.kind)")
        }
    }

}
