import Testing
@testable import Myron

// MARK: - Runtime Primitives

// A primitive defined on the runtime belongs to the host as a whole rather than
// to one session, so every process on that runtime can reach it: each session,
// and each process spawned from them. A process's own definitions are looked up
// first, then the runtime's, then the standard library's.

@Suite("Runtime Primitives")

struct RuntimePrimitiveTests {

    private static let echo = """
        (module echo (go)
          (define (go reply-to) (send reply-to (hostly))))
        """

    // MARK: Reach

    @Test("every session on the runtime reaches a runtime primitive")
    func everySessionReaches() throws {
        let runtime = MyronRuntime()
        let first = runtime.makeSession()
        let second = runtime.makeSession()
        try runtime.define("hostly") { _ in 9 }

        #expect(first.eval("(hostly)").asSuccess?.asInteger == 9)
        #expect(second.eval("(hostly)").asSuccess?.asInteger == 9)
    }

    @Test("a spawned process reaches a runtime primitive")
    func spawnedProcessReaches() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try runtime.define("hostly") { _ in 9 }

        let source = Self.echo + " (spawn (echo) echo.go self) (receive)"
        #expect(session.eval(source).asSuccess?.asInteger == 9)
    }

    @Test("a runtime primitive is reachable from an inner scope", arguments: [
        ("((lambda (x) (+ x (hostly))) 1)", "10"),
        ("(let ((x 1)) (+ x (hostly)))", "10"),
        ("(define (f) (hostly)) (f)", "9")
    ] as [ValueCase])
    func innerScopeReaches(_ c: ValueCase) throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try runtime.define("hostly") { _ in 9 }

        #expect(session.eval(c.source).asSuccess?.description == c.expected)
    }

    @Test("a primitive defined after a session exists is visible to it")
    func definedLaterIsVisible() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        #expect(session.eval("(hostly)").asFailure?.first?.reason == .unrecognisedSymbol)

        try runtime.define("hostly") { _ in 9 }
        #expect(session.eval("(hostly)").asSuccess?.asInteger == 9)
    }

    @Test("a runtime primitive is not visible on another runtime")
    func otherRuntimeCannotSee() throws {
        let runtime = MyronRuntime()
        try runtime.define("hostly") { _ in 9 }

        let other = MyronRuntime().makeSession()
        #expect(other.eval("(hostly)").asFailure?.first?.reason == .unrecognisedSymbol)
        #expect(other.query("hostly") == nil)
    }

    @Test("a body of every arity receives its arguments in order")
    func everyArityInOrder() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try runtime.define("a0") { _ in MyronValue.list([]) }
        try runtime.define("a1") { _, a in [a] }
        try runtime.define("a2") { _, a, b in [a, b] }
        try runtime.define("a3") { _, a, b, c in [a, b, c] }
        try runtime.define("a4") { _, a, b, c, d in [a, b, c, d] }
        try runtime.define("a5") { _, a, b, c, d, e in [a, b, c, d, e] }
        try runtime.define("a6") { _, a, b, c, d, e, f in [a, b, c, d, e, f] }
        try runtime.define("an", arity: .unspecified) { _, values in values }

        #expect(session.eval("(a0)").asSuccess?.description == "()")
        #expect(session.eval("(a1 1)").asSuccess?.description == "(1)")
        #expect(session.eval("(a2 1 2)").asSuccess?.description == "(1 2)")
        #expect(session.eval("(a3 1 2 3)").asSuccess?.description == "(1 2 3)")
        #expect(session.eval("(a4 1 2 3 4)").asSuccess?.description == "(1 2 3 4)")
        #expect(session.eval("(a5 1 2 3 4 5)").asSuccess?.description == "(1 2 3 4 5)")
        #expect(session.eval("(a6 1 2 3 4 5 6)").asSuccess?.description == "(1 2 3 4 5 6)")
        #expect(session.eval("(an 1 2 3 4 5 6 7)").asSuccess?.description == "(1 2 3 4 5 6 7)")
    }

    // MARK: Shadowing

    @Test("a session's own primitive shadows the runtime's, for that session only")
    func sessionPrimitiveShadows() throws {
        let runtime = MyronRuntime()
        let shadowing = runtime.makeSession()
        let other = runtime.makeSession()
        try runtime.define("hostly") { _ in 9 }
        try shadowing.define("hostly") { _ in 1 }

        #expect(shadowing.eval("(hostly)").asSuccess?.asInteger == 1)
        #expect(other.eval("(hostly)").asSuccess?.asInteger == 9)
    }

    @Test("Myron's own define shadows a runtime primitive, for that session only")
    func myronDefineShadows() throws {
        let runtime = MyronRuntime()
        let shadowing = runtime.makeSession()
        let other = runtime.makeSession()
        try runtime.define("hostly") { _ in 9 }

        #expect(shadowing.eval("(define hostly 99) hostly").asSuccess?.asInteger == 99)
        #expect(other.eval("(hostly)").asSuccess?.asInteger == 9)
    }

    @Test("a runtime primitive shadows a standard library name")
    func shadowsStandardLibrary() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try runtime.define("not") { _, _ in "shadowed" }

        #expect(session.eval("(not true)").asSuccess?.asString == "shadowed")
    }

    @Test("defining the same name twice keeps the last definition")
    func redefinitionKeepsTheLast() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try runtime.define("twice") { _ in 1 }
        try runtime.define("twice") { _ in 2 }

        #expect(session.eval("(twice)").asSuccess?.asInteger == 2)
    }

    // MARK: Names

    @Test("a runtime primitive is visible through the environment API")
    func visibleThroughTheEnvironment() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try runtime.define("hostly") { _ in 9 }

        #expect(session.query("hostly")?.kind == .primitive)
        #expect(session.names.contains("hostly"))
    }

    @Test("a reserved name cannot be defined on the runtime", arguments: [
        "spawn", "self", "if", "define", "lambda"
    ])
    func reservedNameRejected(_ name: String) {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let error = #expect(throws: MyronError.self) {
            try runtime.define(name) { _, _ in 1 }
        }

        #expect(error?.reason == .invalidName(name))
        #expect(!session.names.contains(name))
    }

    @Test("a rejected name leaves the runtime untouched")
    func rejectedNameLeavesNothingBehind() {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let before = session.names
        #expect(throws: MyronError.self) { try runtime.define("if") { _, _ in 1 } }
        #expect(throws: MyronError.self) { try runtime.define("no good") { _, _ in 1 } }

        #expect(session.names == before)
    }

    @Test("a runtime primitive written with an ellipsis gets the ellipsis hint")
    func ellipsisHint() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try runtime.define("hostly") { _ in 9 }

        let error = try #require(session.eval("(hostly...)").asFailure?.first)
        #expect(error.reason == .unrecognisedSymbol)
        #expect(error.hints == [.nameWasWrittenWithEllipsis("hostly")])
    }

}
