import Testing
@testable import Myron

// MARK: - Scheduling

// A `send` to a process that is waiting puts it on the runtime's run queue, and
// the runtime runs the queue until it is empty: after every `eval` and `resume`,
// and whenever the host calls `runSchedule`. A session process the scheduler
// finishes keeps its result until the host collects it with `resume`; a spawned
// process has no one to collect it, so it is shut down instead.

@Suite("Scheduling")

struct SchedulingTests {

    // Two sessions on one runtime, where `sender` can name `waiter` as `w`.
    private static func pair() throws -> (MyronRuntime, waiter: MyronSession, sender: MyronSession) {
        let runtime = MyronRuntime()
        let waiter = runtime.makeSession()
        let sender = runtime.makeSession()
        try sender.set("w", to: .process(waiter.process))
        return (runtime, waiter, sender)
    }

    // A host primitive, `pump`, that runs the runtime's schedule. Weak, since
    // the session holds the primitive.
    private final class Pump: @unchecked Sendable {
        weak var runtime: MyronRuntime?
    }

    private static func definePump(in session: MyronSession) throws {
        let pump = Pump()
        pump.runtime = session.runtime
        try session.define("pump") { _ in
            pump.runtime?.runSchedule()
            return MyronValue.nothing
        }
    }

    private static let echo = """
        (module echo (go)
          (define (go reply-to) (send reply-to (+ 1 (receive)))))
        """

    // MARK: Pending Results

    @Test("a send to a waiting session lets the scheduler finish it, and resume hands over the result")
    func schedulerFinishesSession() throws {
        let (_, waiter, sender) = try Self.pair()

        #expect(waiter.eval("(+ 1 (receive))").isWaiting)
        #expect(!waiter.hasPendingResult)

        _ = sender.eval("(send w 41)")
        #expect(waiter.hasPendingResult)

        #expect(waiter.resume().asSuccess?.asInteger == 42)
        #expect(!waiter.hasPendingResult)
        #expect(waiter.resume().asFailure?.first?.reason == .processCannotResume("ready"))
    }

    @Test("a second send does not overwrite a result that is waiting to be collected")
    func secondSendKeepsResult() throws {
        let (runtime, waiter, sender) = try Self.pair()

        _ = waiter.eval("(receive)")
        _ = sender.eval("(send w 1)")
        _ = sender.eval("(send w 2)")

        #expect(waiter.resume().asSuccess?.asInteger == 1)
        #expect(runtime.mailbox(of: waiter.process)?.map(\.content.description) == ["2"])
    }

    @Test("a send to a process that is not waiting leaves it to receive later")
    func sendToReadyProcess() throws {
        let (runtime, waiter, sender) = try Self.pair()

        _ = sender.eval("(send w 1)")
        #expect(!runtime.hasPendingWork)
        #expect(!waiter.hasPendingResult)

        #expect(waiter.eval("(receive)").asSuccess?.asInteger == 1)
    }

    @Test("a pending result may be a failure")
    func pendingFailure() throws {
        let (_, waiter, sender) = try Self.pair()

        _ = waiter.eval("(head (receive))")
        _ = sender.eval("(send w 1)")
        #expect(waiter.hasPendingResult)

        let errors = try #require(waiter.resume().asFailure)
        #expect(errors.first?.reason == .unexpectedType(.integer, [.string, .list]))
        #expect(waiter.eval("(+ 1 1)").asSuccess?.asInteger == 2)
    }

    @Test("a new evaluation discards a result that was not collected")
    func evalDiscardsPendingResult() throws {
        let (_, waiter, sender) = try Self.pair()

        _ = waiter.eval("(+ 1 (receive))")
        _ = sender.eval("(send w 41)")
        #expect(waiter.hasPendingResult)

        #expect(waiter.eval("(+ 1 1)").asSuccess?.asInteger == 2)
        #expect(!waiter.hasPendingResult)
        #expect(waiter.resume().asFailure?.first?.reason == .processCannotResume("ready"))
    }

    @Test("a process woken by another sender keeps waiting for the one it named")
    func receiveFromStaysWaiting() throws {
        let runtime = MyronRuntime()
        let waiter = runtime.makeSession()
        let named = runtime.makeSession()
        let other = runtime.makeSession()
        try waiter.set("named", to: .process(named.process))
        try named.set("w", to: .process(waiter.process))
        try other.set("w", to: .process(waiter.process))

        #expect(waiter.eval("(receive-from named)").isWaiting)

        _ = other.eval("(send w 'other)")
        #expect(!waiter.hasPendingResult)

        _ = named.eval("(send w 'named)")
        #expect(waiter.resume().asSuccess?.asSymbol == "named")
        #expect(runtime.mailbox(of: waiter.process)?.map(\.content.description) == ["other"])
    }

    // MARK: Driving the Schedule

    @Test("a fresh runtime has no pending work, and running it does nothing")
    func nothingToRun() {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        #expect(!runtime.hasPendingWork)

        runtime.runSchedule()
        #expect(!runtime.hasPendingWork)
        #expect(!session.hasPendingResult)
    }

    @Test("a host send queues a waiting process until the host runs the schedule")
    func hostSendWaitsForHost() throws {
        let runtime = MyronRuntime()
        let waiter = runtime.makeSession()
        let host = runtime.makeSession()

        _ = waiter.eval("(+ 1 (receive))")
        try host.send(41, to: waiter.process)
        #expect(runtime.hasPendingWork)
        #expect(!waiter.hasPendingResult)

        runtime.runSchedule()
        #expect(!runtime.hasPendingWork)
        #expect(waiter.hasPendingResult)
        #expect(waiter.resume().asSuccess?.asInteger == 42)
    }

    @Test("a process resumed by hand is not resumed again by the scheduler")
    func resumedByHand() throws {
        let runtime = MyronRuntime()
        let waiter = runtime.makeSession()
        let host = runtime.makeSession()

        _ = waiter.eval("(+ 1 (receive))")
        try host.send(41, to: waiter.process)

        #expect(waiter.resume().asSuccess?.asInteger == 42)
        #expect(!runtime.hasPendingWork)
        #expect(!waiter.hasPendingResult)
        #expect(waiter.resume().asFailure?.first?.reason == .processCannotResume("ready"))
    }

    @Test("a host primitive may run the schedule during an evaluation")
    func pumpDuringEvaluation() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        try Self.definePump(in: session)

        _ = session.eval(Self.echo + " (define c (spawn (echo) echo.go self))")

        // The child runs inside `pump` and replies before the `receive`.
        #expect(session.eval("(begin (send c 1) (pump) (receive))").asSuccess?.asInteger == 2)
        #expect(runtime.processCount == 1)
    }

    @Test("a process the scheduler resumed may run the schedule itself")
    func pumpFromScheduledProcess() throws {
        let runtime = MyronRuntime()
        let waiter = runtime.makeSession()
        let host = runtime.makeSession()
        try Self.definePump(in: waiter)

        let child = try #require(host.eval(Self.echo + " (spawn (echo) echo.go self)").asSuccess?.asProcess)
        _ = waiter.eval("(begin (receive) (pump) 'done)")

        try host.send(0, to: waiter.process)
        try host.send(1, to: child)
        runtime.runSchedule()

        #expect(waiter.resume().asSuccess?.asSymbol == "done")
        #expect(runtime.mailbox(of: host.process)?.map(\.content.description) == ["2"])
        #expect(runtime.processCount == 2)
    }

    // MARK: Spawned Processes

    @Test("a spawned process waits for a message, then finishes and is gone")
    func childFinishesAndGoes() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()

        _ = session.eval(Self.echo + " (define c (spawn (echo) echo.go self))")
        #expect(runtime.processCount == 2)

        #expect(session.eval("(send c 41) (receive)").asSuccess?.asInteger == 42)
        #expect(runtime.processCount == 1)
    }

    @Test("a spawned process keeps no pending result")
    func childKeepsNoResult() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()

        let child = try #require(session.eval(Self.echo + " (spawn (echo) echo.go self)").asSuccess?.asProcess)
        try session.send(1, to: child)
        runtime.runSchedule()

        #expect(!runtime.hasPendingResult(for: child))
        #expect(runtime.processCount == 1)
        #expect(session.eval("(receive)").asSuccess?.asInteger == 2)
    }

    @Test("a spawned process that fails after a resume is gone and the parent carries on")
    func childFailsAfterResume() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let source = """
            (module m (go) (define (go) (head (receive))))
            (define c (spawn (m) m.go))
            (send c 1)
            'carried-on
            """

        #expect(session.eval(source).asSuccess?.asSymbol == "carried-on")
        #expect(runtime.processCount == 1)
    }

    @Test("ping and pong exchange messages until ping is done, and pong keeps waiting")
    func pingPong() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let source = """
            (module pong (go)
              (define (go) (send (receive) 'pong) (go)))
            (module ping (go)
              (define (go partner n reporter)
                (if (eq n 0)
                    (send reporter 'done)
                    (begin (send partner self) (receive) (go partner (- n 1) reporter)))))
            (define p (spawn (pong) pong.go))
            (spawn (ping) ping.go p 3 self)
            (receive)
            """

        #expect(session.eval(source).asSuccess?.asSymbol == "done")
        #expect(runtime.processCount == 2)
    }

}
