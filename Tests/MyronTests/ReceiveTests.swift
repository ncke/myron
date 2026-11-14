import Testing
@testable import Myron

// MARK: - Receive

// `receive` takes the oldest message from the process's mailbox, and
// `receive-from` the oldest from one sender. When nothing matches, the
// evaluation waits and the session reports `.waiting`; a later `resume` calls
// the receive again and carries on from where it stopped. These tests send from
// the host and resume by hand; the Scheduling tests cover the runtime waking a
// waiting process itself.

@Suite("Receive")

struct ReceiveTests {

    typealias ResumeCase = (source: String, before: [Int], batches: [[Int]], expected: String)

    private static func address(of session: MyronSession) throws -> MyronProcess {
        try #require(session.eval("self").asSuccess?.asProcess)
    }

    // A host primitive that evaluates its argument in the same session, the
    // way the runner's `load` does. It records the inner result and fails if
    // the inner evaluation did not succeed.
    private final class Nested: @unchecked Sendable {
        weak var session: MyronSession?
        var results = [MyronResult]()
    }

    private static func defineInner(in session: MyronSession) throws -> Nested {
        let nested = Nested()
        nested.session = session
        try session.define("inner") { _, source in
            let result = try #require(nested.session).eval(try source.requireString())
            nested.results.append(result)
            guard let value = result.asSuccess else { throw MyronHostError("inner did not succeed") }
            return value
        }
        return nested
    }

    // MARK: Receiving

    @Test("receive takes the oldest message", arguments: [
        ("(send self 1) (receive)", "1"),
        ("(send self 1) (send self 2) (list (receive) (receive))", "(1 2)"),
        ("(send self '(a b)) (receive)", "(a b)"),
        ("(send self 1) (send self 2) (map receive-from (list self self))", "(1 2)")
    ] as [ValueCase])
    func receiveOldest(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("receive is an ordinary procedure", arguments: [
        ("(callable? receive)", "true"),
        ("(callable? receive-from)", "true"),
        ("(send self 1) (apply receive (list))", "1"),
        ("(send self 1) (apply receive-from (list self))", "1")
    ] as [ValueCase])
    func receiveIsFirstClass(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("receive is a standard name, so it can be shadowed", arguments: [
        ("(define receive 1) receive", "1"),
        ("(let ((receive-from 2)) receive-from)", "2")
    ] as [ValueCase])
    func receiveCanBeShadowed(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("receive takes no arguments, receive-from takes one",
          arguments: ["(receive 1)", "(receive-from)", "(receive-from self self)"])
    func receiveArity(_ source: String) {
        expectArityFailure(source)
    }

    @Test("receive-from's sender must be a process")
    func receiveFromSender() {
        expectFailure("(send self 1) (receive-from 1)")
    }

    @Test("a received message leaves the mailbox")
    func receiveConsumes() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let me = try Self.address(of: session)

        _ = session.eval("(send self 1) (send self 2) (receive)")

        let mailbox = try #require(runtime.mailbox(of: me))
        #expect(mailbox.map(\.content.description) == ["2"])
    }

    @Test("receive-from skips other senders and leaves their messages in order")
    func receiveFromIsSelective() throws {
        let runtime = MyronRuntime()
        let first = runtime.makeSession()
        let second = runtime.makeSession()
        let a = try Self.address(of: first)
        let b = try Self.address(of: second)

        try first.set("b", to: .process(b))
        try second.set("a", to: .process(a))
        _ = first.eval("(send b 'a1) (send b 'a2)")
        _ = second.eval("(send self 'b1)")

        #expect(second.eval("(receive-from self)").asSuccess?.description == "b1")
        #expect(second.eval("(receive-from a)").asSuccess?.description == "a1")
        #expect(runtime.mailbox(of: b)?.map(\.content.description) == ["a2"])
    }

    // MARK: Waiting

    @Test("receive on an empty mailbox waits")
    func emptyMailboxWaits() {
        let session = MyronSession()
        #expect(session.eval("(receive)").isWaiting)
    }

    // Each batch is sent before a resume; every resume but the last keeps
    // waiting, and the last gives the expected value.
    @Test("resume carries on from the receive that waited", arguments: [
        ("(+ 1 (receive))", [], [[41]], "42"),
        ("(list 0 (receive) (receive) 3)", [1], [[2]], "(0 1 2 3)"),
        ("(list (receive) (receive))", [], [[1], [2]], "(1 2)"),
        ("(map receive-from (list self self))", [], [[1], [2]], "(1 2)"),
        ("(map receive-from (list self self))", [1], [[2]], "(1 2)"),
        ("(let ((x (receive))) (* x 2))", [], [[21]], "42"),
        ("((lambda (x) (+ x (receive))) 1)", [], [[2]], "3"),
        ("(cond ((== (receive) 1) 'one) (true 'other))", [], [[1]], "one")
    ] as [ResumeCase])
    func resumeCarriesOn(_ c: ResumeCase) throws {
        let session = MyronSession()
        let me = try Self.address(of: session)

        for n in c.before { try session.send(.integer(n), to: me) }
        #expect(session.eval(c.source).isWaiting)

        for (index, batch) in c.batches.enumerated() {
            for n in batch { try session.send(.integer(n), to: me) }
            let result = session.resume()

            if index < c.batches.count - 1 {
                #expect(result.isWaiting, "\(c.source) batch \(index) got \(result)")
            } else {
                #expect(result.asSuccess?.description == c.expected, "\(c.source) got \(result)")
            }
        }
    }

    @Test("a procedure defined earlier can wait when called")
    func procedureWaits() throws {
        let session = MyronSession()
        let me = try Self.address(of: session)

        _ = session.eval("(define (next) (+ 1 (receive)))")
        #expect(session.eval("(next)").isWaiting)

        try session.send(1, to: me)
        #expect(session.resume().asSuccess?.description == "2")
    }

    @Test("resuming with nothing to receive keeps waiting")
    func resumeWithoutMessage() throws {
        let session = MyronSession()
        let me = try Self.address(of: session)

        #expect(session.eval("(+ 1 (receive))").isWaiting)
        #expect(session.resume().isWaiting)

        try session.send(1, to: me)
        #expect(session.resume().asSuccess?.description == "2")
    }

    @Test("receive-from keeps waiting until that sender sends")
    func receiveFromWaitsForSender() throws {
        let runtime = MyronRuntime()
        let first = runtime.makeSession()
        let second = runtime.makeSession()
        let a = try Self.address(of: first)
        let b = try Self.address(of: second)

        try first.set("b", to: .process(b))
        try second.set("a", to: .process(a))

        #expect(second.eval("(receive-from a)").isWaiting)

        try second.send("own", to: b)
        #expect(second.resume().isWaiting)

        _ = first.eval("(send b 'from-a)")
        #expect(second.resume().asSuccess?.description == "from-a")
        #expect(runtime.mailbox(of: b)?.map(\.content.description) == ["\"own\""])
    }

    @Test("a process evaluates normally after a resume completes")
    func readyAfterResume() throws {
        let session = MyronSession()
        let me = try Self.address(of: session)

        _ = session.eval("(+ 1 (receive))")
        try session.send(1, to: me)
        _ = session.resume()

        #expect(session.eval("(+ 1 1)").asSuccess?.description == "2")
        #expect(session.eval("(receive)").isWaiting)
    }

    @Test("an error after a resume is reported and the process recovers")
    func errorAfterResume() throws {
        let session = MyronSession()
        let me = try Self.address(of: session)

        _ = session.eval("(head (receive))")
        try session.send(1, to: me)

        let errors = try #require(session.resume().asFailure)
        #expect(errors.first?.reason == .unexpectedType(.integer, [.string, .list]))
        #expect(session.eval("(+ 1 1)").asSuccess?.description == "2")
    }

    // MARK: Process State

    @Test("a waiting process cannot start another evaluation")
    func evalWhileWaiting() throws {
        let session = MyronSession()
        let me = try Self.address(of: session)

        _ = session.eval("(+ 1 (receive))")

        let errors = try #require(session.eval("(+ 1 1)").asFailure)
        #expect(errors.first?.reason == .processNotReady("waiting"))

        try session.send(1, to: me)
        #expect(session.resume().asSuccess?.description == "2")
    }

    @Test("a process that is not waiting cannot resume")
    func resumeWhenReady() throws {
        let session = MyronSession()
        _ = session.eval("(+ 1 1)")

        let errors = try #require(session.resume().asFailure)
        #expect(errors.first?.reason == .processCannotResume("ready"))
        #expect(session.eval("(+ 1 1)").asSuccess?.description == "2")
    }

    // MARK: Nested Evaluation

    // A nested evaluation runs on top of the host's Swift frames, so it has no
    // continuation to keep. Blocking there is an error rather than a wait.
    @Test("receive cannot wait inside a nested evaluation")
    func nestedCannotWait() throws {
        let session = MyronSession()
        let nested = try Self.defineInner(in: session)

        #expect(session.eval("(list 1 (inner \"(receive)\") 3)").isFailure)
        #expect(nested.results.first?.asFailure?.first?.reason == .cannotReceiveInsideNestedEvaluation)

        #expect(session.resume().asFailure?.first?.reason == .processCannotResume("ready"))
        #expect(session.eval("(+ 1 1)").asSuccess?.description == "2")
    }

    @Test("receive inside a nested evaluation takes a waiting message")
    func nestedWithMessage() throws {
        let session = MyronSession()
        let me = try Self.address(of: session)
        _ = try Self.defineInner(in: session)

        try session.send(2, to: me)
        #expect(session.eval("(list 1 (inner \"(receive)\") 3)").asSuccess?.description == "(1 2 3)")
    }

    @Test("an error after a nested evaluation is reported as itself")
    func errorAfterNested() throws {
        let session = MyronSession()
        _ = try Self.defineInner(in: session)

        let errors = try #require(session.eval("(list (inner \"(+ 1 1)\") (head 1))").asFailure)
        #expect(errors.first?.reason == .unexpectedType(.integer, [.string, .list]))
    }

}
