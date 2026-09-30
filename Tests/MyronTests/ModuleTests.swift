import Testing
@testable import Myron

// MARK: - Modules

@Suite("Modules")

struct ModuleTests {

    private static let geo = """
        (module geo (area circumference)
          (define (square x) (* x x))
          (define (area r) (* 3 (square r)))
          (define (circumference r) (* 6 r)))
        """

    private static func failure(_ source: String) -> MyronError? {
        guard case .failure(let errors) = MyronSession().eval(source) else {
            Issue.record("\(source) did not fail")
            return nil
        }

        return errors.first
    }

    // MARK: Defining

    @Test("module defines its name, bound to a module value")
    func moduleDefinesName() {
        expectValue(Self.geo, "<define: geo>")
        expectValue(Self.geo + "\ngeo", "<module: geo>")
        expectValue(Self.geo + "\n(kind geo)", "\"module\"")
    }

    @Test("a module binds nothing but its own name", arguments: [
        "area", "circumference", "square"
    ])
    func moduleBindsOnlyItsName(_ name: String) {
        expectFailure(Self.geo + "\n\(name)", reason: .unrecognisedSymbol)
    }

    @Test("a module may have no exports and no body")
    func emptyModule() {
        expectValue("(module empty ())", "<define: empty>")
        expectValue("(module empty ()) (import empty)", "()")
        expectValue("(module quiet () (define x 1))", "<define: quiet>")
    }

    @Test("a module body is evaluated in order")
    func bodyInOrder() {
        expectValue(
            """
            (module m (b) (define a 1) (define b (+ a 1)))
            (import m)
            b
            """,
            "2")
    }

    @Test("a module body sees the names around it")
    func moduleSeesOuterNames() {
        expectValue(
            """
            (define scale 10)
            (module m (f) (define (f x) (* scale x)))
            (import m)
            (f 2)
            """,
            "20")
    }

    @Test("a module body can import a module defined before it")
    func moduleUsesSibling() {
        expectValue(
            Self.geo + """

            (module solid (volume)
              (import geo)
              (define (volume r h) (* (area r) h)))
            (import solid)
            (volume 1 2)
            """,
            "6")
    }

    @Test("a module can re-export what it imports")
    func reexport() {
        expectValue(
            Self.geo + """

            (module shapes (area) (import geo))
            (import shapes)
            (area 2)
            """,
            "12")
    }

    @Test("a failing module body leaves its name unbound")
    func failingBody() {
        let session = MyronSession()
        #expect(session.eval("(module m (x) (define x (/ 1 0)))").asFailure?.first?.reason
            == .divisionByZero)
        #expect(session.eval("m").asFailure?.first?.reason == .unrecognisedSymbol)
    }

    // MARK: Exports

    @Test("an export must be defined in the module itself", arguments: [
        ("(module m (x))", "m", ["x"]),
        ("(module m (x) (define y 1))", "m", ["x"]),
        ("(module m (length))", "m", ["length"]),
        ("(define x 1) (module m (x))", "m", ["x"]),
        ("(module m (b a c) (define c 1))", "m", ["b", "a"])
    ] as [(String, String, [String])])
    func missingExports(_ source: String, _ module: String, _ missing: [String]) {
        guard let error = Self.failure(source) else { return }
        #expect(error.reason == .unrecognisedSymbol)
        #expect(error.hints == [.moduleDidNotDefineExports(module, missing)])
    }

    @Test("exports come from the module's frame, not the standard library")
    func exportShadowsStandard() {
        expectValue(
            """
            (module m (length) (define (length xs) 'mine))
            (import m)
            (length '(1 2))
            """,
            "mine")
    }

    // MARK: Names

    @Test("a module name cannot contain a dot")
    func dottedModuleName() {
        guard let error = Self.failure("(module a.b (x) (define x 1))") else { return }
        #expect(error.reason == .invalidName("a.b"))
        #expect(error.hints == [.moduleNamesCannotBeDotted("a.b")])
    }

    @Test("an exported name cannot contain a dot")
    func dottedExportName() {
        guard let error = Self.failure("(module m (x.y) (define x.y 1))") else { return }
        #expect(error.reason == .invalidName("x.y"))
        #expect(error.hints == [.moduleCannotExportDottedName("m", "x.y")])
    }

    // An imported `if` could never be reached in head position.
    @Test("an exported name cannot be a special form's name", arguments: [
        "if", "import", "module"
    ])
    func reservedExportName(_ name: String) {
        guard let error = Self.failure("(module m (\(name)) (define \(name) 1))") else { return }
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [.cannotUseReservedName(name)])
    }

    @Test("a module cannot take a special form's name", arguments: [
        "module", "import", "if", "define"
    ])
    func reservedModuleName(_ name: String) {
        guard let error = Self.failure("(module \(name) (x) (define x 1))") else { return }
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [.cannotUseReservedName(name)])
    }

    @Test("a record type name may still contain a dot")
    func dottedRecordTypeName() {
        expectValue("(make-record-type 'acme.point '(x y))", "<record-type: acme.point x y>")
    }

    // MARK: Importing

    @Test("import binds a module's exports")
    func importBindsExports() {
        expectValue(Self.geo + "\n(import geo)\n(area 2)", "12")
        expectValue(Self.geo + "\n(import geo)\n(circumference 1)", "6")
    }

    @Test("import leaves a module's private names unbound")
    func importKeepsPrivates() {
        expectFailure(Self.geo + "\n(import geo)\nsquare", reason: .unrecognisedSymbol)
    }

    @Test("an imported procedure still reaches the module's private names")
    func importedClosure() {
        expectValue(Self.geo + "\n(import geo)\n(map area '(1 2))", "(3 12)")
    }

    @Test("import gives back the names it bound, in order")
    func importResult() {
        expectValue(Self.geo + "\n(import geo)", "(<define: area> <define: circumference>)")
        expectValue(
            """
            (module m (e d c b a)
              (define a 1) (define b 2) (define c 3) (define d 4) (define e 5))
            (import m)
            """,
            "(<define: a> <define: b> <define: c> <define: d> <define: e>)")
    }

    @Test("import takes several modules")
    func importSeveral() {
        expectValue(
            Self.geo + """

            (module greek (tau) (define tau 6))
            (import geo greek)
            (circumference tau)
            """,
            "36")
    }

    @Test("a later import replaces an earlier binding of the same name")
    func importReplaces() {
        expectValue(
            """
            (define x 1)
            (module m (x) (define x 2))
            (import m)
            x
            """,
            "2")
    }

    @Test("import inside a procedure binds only for that call")
    func importInProcedure() {
        let source = Self.geo + "\n(define (g) (import geo) (area 1))"
        expectValue(source + "\n(g)", "3")
        expectFailure(source + "\n(g)\narea", reason: .unrecognisedSymbol)
    }

    @Test("import inside a let binds only within it")
    func importInLet() {
        let source = Self.geo + "\n(let ((r 2)) (import geo) (area r))"
        expectValue(source, "12")
        expectFailure(source + "\narea", reason: .unrecognisedSymbol)
    }

    @Test("import errors", arguments: [
        ("(import)", .unexpectedArity(0, .atLeast(1))),
        ("(import nope)", .unrecognisedSymbol),
        ("(define x 5) (import x)", .unexpectedType(.integer, [.module])),
        ("(import 5)", .unexpectedType(.integer, [.symbol])),
        ("(import (geo))", .unexpectedType(.list, [.symbol]))
    ] as [FailureCase])
    func importErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("module errors", arguments: [
        ("(module m)", .unexpectedArity(1, .atLeast(2))),
        ("(module 1 ())", .unexpectedType(.integer, [.symbol])),
        ("(module m x)", .unexpectedType(.symbol, [.list])),
        ("(module m (1))", .unexpectedType(.integer, [.symbol]))
    ] as [FailureCase])
    func moduleErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: Qualified Access

    @Test("a qualified name reaches an export without importing it")
    func qualifiedAccess() {
        expectValue(Self.geo + "\n(geo.area 2)", "12")
        expectValue(Self.geo + "\n(map geo.circumference '(1 2))", "(6 12)")
        expectFailure(Self.geo + "\n(geo.area 2)\narea", reason: .unrecognisedSymbol)
    }

    @Test("a qualified name walks through nested modules")
    func qualifiedNested() {
        let nested = "(module outer (inner) (module inner (x) (define x 42)))"
        expectValue(nested + "\nouter.inner.x", "42")
        expectValue(nested + "\nouter.inner", "<module: inner>")
        expectValue(nested + "\n(import outer.inner)\nx", "42")
    }

    @Test("a qualified name follows lexical scope")
    func qualifiedLexical() {
        expectValue(Self.geo + "\n(let ((g geo)) (g.area 1))", "3")
        expectValue("(define (f) (module local (y) (define y 7)) local.y) (f)", "7")
        expectFailure(
            "(module m (x) (define x 1)) (define (f m) m.x) (f 5)",
            reason: .unexpectedType(.integer, [.module]))
    }

    @Test("a plain binding with a dotted name comes before qualified access")
    func plainBeforeQualified() {
        expectValue(Self.geo + "\n(define geo.area 99)\ngeo.area", "99")
    }

    @Test("qualified access errors", arguments: [
        ("geo.square", .unrecognisedSymbol),
        ("geo.volume", .unrecognisedSymbol),
        ("nope.x", .unrecognisedSymbol),
        ("(define five 5) five.x", .unexpectedType(.integer, [.module])),
        ("geo.area.x", .unexpectedType(.procedure, [.module])),
        ("geo..area", .unrecognisedSymbol),
        (".geo", .unrecognisedSymbol),
        ("geo.", .unrecognisedSymbol)
    ] as [FailureCase])
    func qualifiedErrors(_ c: FailureCase) {
        expectFailure(Self.geo + "\n" + c.source, reason: c.reason)
    }

    @Test("a name a module does not export is hinted", arguments: [
        (geo + "\ngeo.square", "geo", "square"),
        (geo + "\ngeo.volume", "geo", "volume"),
        ("(module outer (inner) (module inner (x) (define x 1)))\nouter.inner.y", "inner", "y")
    ])
    func missingExportHint(_ source: String, _ module: String, _ name: String) {
        guard let error = Self.failure(source) else { return }
        #expect(error.reason == .unrecognisedSymbol)
        #expect(error.hints == [.moduleDoesNotExport(module, name)])
    }

    @Test("an empty segment or an unknown module has no export hint", arguments: [
        "geo..area", "geo.", "nope.x"
    ])
    func noExportHint(_ name: String) {
        guard let error = Self.failure(Self.geo + "\n" + name) else { return }
        #expect(error.reason == .unrecognisedSymbol)
        #expect((error.hints ?? []).isEmpty)
    }

    @Test("a host can query a qualified name")
    func qualifiedQuery() {
        let session = MyronSession()
        _ = session.eval(Self.geo)
        #expect(session.query("geo.area")?.kind == .procedure)
        #expect(session.query("geo.square") == nil)
        #expect(session.query("nope.x") == nil)
    }

    // MARK: Predicates

    @Test("module?", arguments: [
        ("(module? geo)", "true"),
        ("(define g geo) (module? g)", "true"),
        ("(module? 'geo)", "false"),
        ("(module? geo.area)", "false"),
        ("(module? nothing)", "false"),
        ("(module? '())", "false")
    ] as [ValueCase])
    func isModule(_ c: ValueCase) {
        expectValue(Self.geo + "\n" + c.source, c.expected)
    }

    @Test("exports? with one name", arguments: [
        ("(exports? 'area geo)", "true"),
        ("(exports? \"area\" geo)", "true"),
        ("(exports? 'circumference geo)", "true"),
        ("(exports? 'square geo)", "false"),
        ("(exports? 'volume geo)", "false"),
        ("(exports? 'geo.area geo)", "false")
    ] as [ValueCase])
    func exportsName(_ c: ValueCase) {
        expectValue(Self.geo + "\n" + c.source, c.expected)
    }

    @Test("exports? with a list asks for every name", arguments: [
        ("(exports? '(area circumference) geo)", "true"),
        ("(exports? '(area \"circumference\") geo)", "true"),
        ("(exports? '(area) geo)", "true"),
        ("(exports? '(area square) geo)", "false"),
        ("(exports? '(volume area) geo)", "false"),
        ("(exports? '() geo)", "true")
    ] as [ValueCase])
    func exportsList(_ c: ValueCase) {
        expectValue(Self.geo + "\n" + c.source, c.expected)
    }

    @Test("exports? sees what a module re-exports")
    func exportsReexport() {
        expectValue(
            Self.geo + "\n(module shapes (area) (import geo))\n(exports? 'area shapes)",
            "true")
    }

    @Test("module predicate errors", arguments: [
        ("(module?)", .unexpectedArity(0, .exactly(1))),
        ("(module? geo geo)", .unexpectedArity(2, .exactly(1))),
        ("(exports? 'area)", .unexpectedArity(1, .exactly(2))),
        ("(exports? 'area 5)", .unexpectedType(.integer, [.module])),
        ("(exports? 5 geo)", .unexpectedType(.integer, [.string, .symbol, .list])),
        ("(exports? '(area 5) geo)", .unexpectedType(.integer, [.string, .symbol])),
        ("(exports? '(volume 5) geo)", .unexpectedType(.integer, [.string, .symbol])),
        ("(exports? '((area)) geo)", .unexpectedType(.list, [.string, .symbol]))
    ] as [FailureCase])
    func modulePredicateErrors(_ c: FailureCase) {
        expectFailure(Self.geo + "\n" + c.source, reason: c.reason)
    }

    // MARK: Module Values

    @Test("a module is a value like any other")
    func moduleIsAValue() {
        expectValue(Self.geo + "\n(list geo)", "(<module: geo>)")
        expectValue(Self.geo + "\n(define g geo)\n(import g)\n(area 1)", "3")
        expectFailure(Self.geo + "\n(geo 1)", reason: .expectedFunction(.module))
    }

    @Test("module equality", arguments: [
        ("(eq geo geo)", "true"),
        ("(define g geo) (eq geo g)", "true"),
        ("(contains? geo (set geo))", "true"),
        ("(length (set geo geo))", "1"),
        ("(module shapes (area) (import geo)) (eq geo shapes)", "false"),
        ("(eq geo 'geo)", "false")
    ] as [ValueCase])
    func moduleEquality(_ c: ValueCase) {
        expectValue(Self.geo + "\n" + c.source, c.expected)
    }

    // MARK: Swift Interop

    @Test("a module reads from Swift")
    func moduleFromSwift() throws {
        let session = MyronSession()
        _ = session.eval(Self.geo)
        let module = try #require(session.query("geo")?.asModule)

        #expect(module.name == "geo")
        #expect(module.exports == ["area", "circumference"])
        #expect(module["area"]?.kind == .procedure)
        #expect(module["square"] == nil)
        #expect(module.description == "<module: geo>")
        #expect(try session.query("geo")?.requireModule() == module)
        #expect(module.myronValue == .module(module))
    }

    @Test("a non-module refuses to convert to a module")
    func nonModuleRefuses() {
        #expect(throws: MyronError.self) { try MyronValue.integer(1).requireModule() }
        #expect(MyronValue.integer(1).asModule == nil)
    }

}
