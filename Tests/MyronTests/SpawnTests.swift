import Testing
@testable import Myron

// MARK: - Spawn

// Until processes can message each other, a spawned process runs its entry
// call to the end before `spawn` returns, and nothing it does can be seen from
// outside. So these pin down the contract around the child: what `spawn`
// accepts, what it rejects, and that the child is gone afterwards.

@Suite("Spawn")

struct SpawnTests {

    private static let geo = """
        (module geo (area)
          (define (square x) (* x x))
          (define (area r) (* 3 (square r))))
        """

    private static let shapes = geo + """

        (module shapes (volume)
          (import geo)
          (define (volume r h) (* (area r) h)))
        """

    private static let boom = """
        (module boom (go)
          (define (go) (raise "child failed")))
        """

    // MARK: Spawning

    @Test("spawn gives back a process", arguments: [
        (geo + " (process? (spawn (geo) geo.area 2))", "true"),
        (geo + " (kind (spawn (geo) geo.area 2))", "\"process\""),
        (geo + " (process? (spawn (geo) geo.area (+ 1 1)))", "true"),
        (shapes + " (process? (spawn (geo shapes) shapes.volume 1 2))", "true")
    ] as [ValueCase])
    func spawnGivesProcess(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("each spawn is a different process")
    func spawnsAreDistinct() {
        expectValue(Self.geo + " (eq (spawn (geo) geo.area 1) (spawn (geo) geo.area 1))", "false")
        expectValue(Self.geo + " (length (set (spawn (geo) geo.area 1) (spawn (geo) geo.area 1)))", "2")
    }

    @Test("the entry may be any name the child can see", arguments: [
        (geo + " (process? (spawn (geo) + 1 2))", "true"),
        (geo + " (process? (spawn () + 1 2))", "true")
    ] as [ValueCase])
    func entryThroughStandardName(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the module is named by its own name, not the name it is bound to")
    func moduleOwnName() {
        expectValue(Self.geo + " (define g geo) (process? (spawn (g) geo.area 2))", "true")
        expectFailure(Self.geo + " (define g geo) (spawn (g) g.area 2)", reason: .unrecognisedSymbol)
    }

    @Test("arguments are evaluated in the parent and may be any sendable value", arguments: [
        (geo + " (define n 2) (process? (spawn (geo) geo.area n))", "true"),
        (geo + " (process? (spawn (geo) geo.area '(1 2)))", "true"),
        (geo + " (process? (spawn (geo) geo.area (list 1 \"a\" 'b (set 1) (make-hashmap))))", "true"),
        (geo + " (define point (make-record-type 'point '(x y)))"
            + " (process? (spawn (geo) geo.area (make-record point 1 2)))", "true")
    ] as [ValueCase])
    func plainArguments(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: Isolation

    // The child's failure belongs to the child. The parent's `spawn` succeeds,
    // and a `try` around it has nothing to catch.
    @Test("a child that fails does not fail the parent", arguments: [
        (boom + " (process? (spawn (boom) boom.go))", "true"),
        (geo + " (process? (spawn (geo) geo.area))", "true"),
        (geo + " (process? (spawn (geo) geo.area 1 2))", "true"),
        (geo + " (process? (spawn (geo) geo.area \"two\"))", "true"),
        (geo + " (process? (spawn (geo) pi))", "true"),
        (boom + " (try (lambda (m) 'caught) ((process? (spawn (boom) boom.go))))", "true")
    ] as [ValueCase])
    func childFailureIsIsolated(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the parent's environment is untouched by the child")
    func parentUntouched() {
        expectValue(Self.geo + " (spawn (geo) geo.area 2) (define square 5) square", "5")
        expectFailure(Self.geo + " (spawn (geo) geo.area 2) area", reason: .unrecognisedSymbol)
    }

    // MARK: Rejections

    @Test("spawn rejects a malformed form", arguments: [
        ("(spawn)", .unexpectedArity(0, .atLeast(2))),
        (geo + " (spawn (geo))", .unexpectedArity(1, .atLeast(2))),
        (geo + " (spawn geo geo.area)", .unexpectedType(.symbol, [.list])),
        (geo + " (spawn (geo) (lambda (x) x) 7)", .unexpectedType(.list, [.symbol])),
        (geo + " (spawn (geo) \"geo.area\")", .unexpectedType(.string, [.symbol])),
        (geo + " (spawn (1) geo.area 2)", .unexpectedType(.integer, [.module])),
        (geo + " (spawn ('geo) geo.area 2)", .unexpectedType(.symbol, [.module]))
    ] as [FailureCase])
    func malformed(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("spawn rejects an entry the child cannot find", arguments: [
        (geo + " (spawn (geo) other.area 2)", .unrecognisedSymbol),
        (geo + " (spawn () geo.area 2)", .unrecognisedSymbol),
        (geo + " (spawn (geo) geo.square 2)", .unrecognisedSymbol),
        (geo + " (spawn (geo) geo.missing 2)", .unrecognisedSymbol),
        (geo + " (spawn (geo) area 2)", .unrecognisedSymbol)
    ] as [FailureCase])
    func unknownEntry(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a module the entry goes through must be in the list")
    func entryModuleHint() {
        guard case .failure(let errors) = MyronSession().eval(Self.geo + " (spawn (geo) other.area 2)") else {
            Issue.record("spawn through an unlisted module did not fail")
            return
        }
        #expect(errors.first?.hints?.contains(.spawnCannotEnterThroughUnrecognisedModule("other")) == true)
    }

    @Test("a module must come after the modules it imports", arguments: [
        (shapes + " (spawn (shapes geo) shapes.volume 1 2)", .unrecognisedSymbol),
        (shapes + " (spawn (shapes) shapes.volume 1 2)", .unrecognisedSymbol)
    ] as [FailureCase])
    func moduleOrder(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    private static let twice = "(defmacro (twice x) (list '+ x x))"

    @Test("an argument must be sendable", arguments: [
        (geo + " (spawn (geo) geo.area (lambda (x) x))", .expectedSendable(.procedure)),
        (geo + " (spawn (geo) geo.area sqrt)", .expectedSendable(.primitive)),
        (geo + " (spawn (geo) geo.area map)", .expectedSendable(.higherOrder)),
        (geo + " " + twice + " (spawn (geo) geo.area twice)", .expectedSendable(.macro)),
        (geo + " (spawn (geo) geo.area geo)", .expectedSendable(.module))
    ] as [FailureCase])
    func nonDataArgument(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // The error names the kind of the part that is not sendable, not of the
    // argument holding it.
    @Test("an argument may not hold anything unsendable, at any depth", arguments: [
        (geo + " (spawn (geo) geo.area (list 1 (lambda (x) x)))", .expectedSendable(.procedure)),
        (geo + " (spawn (geo) geo.area (list (list sqrt)))", .expectedSendable(.primitive)),
        (geo + " (spawn (geo) geo.area (set 1 geo))", .expectedSendable(.module)),
        (geo + " (spawn (geo) geo.area (put 'k (lambda (x) x) (make-hashmap)))",
         .expectedSendable(.procedure)),
        (geo + " (spawn (geo) geo.area (put (lambda (x) x) 'v (make-hashmap)))",
         .expectedSendable(.procedure)),
        (geo + " " + twice + " (spawn (geo) geo.area (list twice))", .expectedSendable(.macro)),
        (geo + " (define box (make-record-type 'box '(item)))"
            + " (spawn (geo) geo.area (make-record box sqrt))", .expectedSendable(.primitive))
    ] as [FailureCase])
    func nestedNonDataArgument(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("the hints name the argument, the part of it that is not sendable, and spawn", arguments: [
        (geo + " (spawn (geo) geo.area geo)",
         MyronError.Hint.valueMustBeSendable("<module: geo>", "<module: geo>", .module)),
        (geo + " (spawn (geo) geo.area (list 1 (lambda (x) x)))",
         MyronError.Hint.valueMustBeSendable("(1 <procedure>)", "<procedure>", .procedure))
    ])
    func nonSendableHints(_ source: String, _ hint: MyronError.Hint) {
        guard case .failure(let errors) = MyronSession().eval(source) else {
            Issue.record("\(source) did not fail")
            return
        }
        #expect(errors.first?.hints == [hint, .spawnCannotEnterWithNonSendableArgument])
    }

    @Test("the spawn hint says the argument cannot be sent")
    func nonSendableSpawnHintWording() {
        #expect(MyronError.Hint.spawnCannotEnterWithNonSendableArgument.description
            == "Spawn cannot enter because the argument is non-sendable")
    }

    // MARK: Lifetime

    @Test("a spawned process is gone once spawn returns")
    func childIsShutDown() {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        #expect(runtime.processCount == 1)

        _ = session.eval(Self.geo + " (spawn (geo) geo.area 2)")
        #expect(runtime.processCount == 1)

        _ = session.eval(Self.boom + " (spawn (boom) boom.go)")
        #expect(runtime.processCount == 1)

        _ = session.eval(Self.geo + " (spawn (geo) geo.missing 2)")
        #expect(runtime.processCount == 1)

        _ = session.eval(Self.shapes + " (spawn (shapes) shapes.volume 1 2)")
        #expect(runtime.processCount == 1)
    }

    @Test("a child may spawn a child of its own")
    func nestedSpawn() {
        let source = """
            (module outer (go)
              (module inner (run) (define (run) 1))
              (define (go) (spawn (inner) inner.run)))
            (process? (spawn (outer) outer.go))
            """

        let runtime = MyronRuntime()
        let session = runtime.makeSession()

        guard case .success(let value) = session.eval(source) else {
            Issue.record("nested spawn failed")
            return
        }
        #expect(value == .boolean(true))
        #expect(runtime.processCount == 1)
    }

    @Test("a session's process leaves the runtime with the session")
    func sessionProcessLifetime() {
        let runtime = MyronRuntime()
        var first: MyronSession? = runtime.makeSession()
        let second = runtime.makeSession()
        #expect(runtime.processCount == 2)

        first = nil
        #expect(first == nil)
        #expect(runtime.processCount == 1)

        _ = second.eval(Self.geo + " (spawn (geo) geo.area 2)")
        #expect(runtime.processCount == 1)
    }

    @Test("sessions sharing a runtime number their processes in one sequence")
    func sharedRuntimeNumbering() {
        let runtime = MyronRuntime()
        let first = runtime.makeSession()
        let second = runtime.makeSession()

        guard
            case .success(let a) = first.eval(Self.geo + " (spawn (geo) geo.area 1)"),
            case .success(let b) = second.eval(Self.geo + " (spawn (geo) geo.area 1)")
        else {
            Issue.record("spawn failed")
            return
        }
        #expect(a == .process(MyronProcess(2)))
        #expect(b == .process(MyronProcess(3)))
    }

}
