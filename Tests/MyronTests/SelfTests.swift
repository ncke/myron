import Testing
@testable import Myron

// MARK: - Self

// `self` is a reserved name that the machine resolves to the process doing the
// evaluating, without looking anything up. Nothing can bind it, so it means the
// same process wherever it is written: in a procedure, a module, a template or
// a macro's expansion.

@Suite("Self")

struct SelfTests {

    // MARK: The Current Process

    @Test("self is a process", arguments: [
        ("(process? self)", "true"),
        ("(kind self)", "\"process\""),
        ("(eq self self)", "true")
    ] as [ValueCase])
    func selfIsProcess(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("each session is its own process")
    func sessionsDiffer() throws {
        let runtime = MyronRuntime()
        let first = runtime.makeSession()
        let second = runtime.makeSession()

        let a = try #require(first.eval("self").asSuccess)
        let b = try #require(second.eval("self").asSuccess)
        #expect(a != b)
        #expect(first.eval("self").asSuccess == a)
    }

    @Test("a spawned process is not the one that spawned it")
    func spawnedDiffers() {
        expectValue("(eq self (spawn () + 1 2))", "false")
    }

    @Test("self means the same process everywhere in it", arguments: [
        ("(define (me) self) (eq (me) self)", "true"),
        ("(let ((f (lambda () self))) (eq (f) self))", "true"),
        ("(eq ((lambda () ((lambda () self)))) self)", "true"),
        ("(module m (me) (define (me) self)) (eq (m.me) self)", "true"),
        ("(eq (try (lambda (e) self) ((raise \"x\"))) self)", "true")
    ] as [ValueCase])
    func selfEverywhere(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    // MARK: As Code

    @Test("quoted, self is just a symbol", arguments: [
        ("'self", "self"),
        ("(symbol? 'self)", "true"),
        ("(eq `(,self) (list self))", "true")
    ] as [ValueCase])
    func quotedSelf(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a macro's expansion can mention self")
    func macroExpansion() {
        expectValue("(defmacro (whoami) 'self) (eq (whoami) self)", "true")
    }

    // MARK: As Data

    @Test("self is sendable, so it can be given to spawn")
    func spawnArgument() {
        expectValue("(process? (spawn () list self))", "true")
    }

    @Test("self cannot be applied")
    func notCallable() {
        expectFailure("(self)", reason: .expectedFunction(.process))
    }

}
