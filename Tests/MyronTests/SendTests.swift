import Testing
@testable import Myron

// MARK: - Send

// `send` puts a sendable value in another process's mailbox. Nothing can take a
// message out yet, so delivery is checked through the runtime's mailboxes: what
// arrived, in what order, and which process it came from.

@Suite("Send")

struct SendTests {

    private static let twice = "(defmacro (twice x) (list '+ x x))"

    private static let echo = """
        (module echo (go)
          (define (go parent) (send parent 'hello)))
        """

    private static func address(of session: MyronSession) throws -> MyronProcess {
        try #require(session.eval("self").asSuccess?.asProcess)
    }

    private static func contents(_ messages: [Message]?) -> [String] {
        (messages ?? []).map(\.content.description)
    }

    // MARK: Sendability

    @Test("sendable?", arguments: [
        ("(sendable? 1)", "true"),
        ("(sendable? \"a\")", "true"),
        ("(sendable? 'a)", "true"),
        ("(sendable? nothing)", "true"),
        ("(sendable? self)", "true"),
        ("(sendable? (list 1 (list 2 3)))", "true"),
        ("(sendable? (set 1 2))", "true"),
        ("(sendable? (put 'k 1 (make-hashmap)))", "true"),
        ("(sendable? (make-record (make-record-type 'box '(item)) 1))", "true"),
        ("(sendable? +)", "false"),
        ("(sendable? map)", "false"),
        ("(sendable? (lambda (x) x))", "false"),
        ("(module m ()) (sendable? m)", "false"),
        (twice + " (sendable? twice)", "false"),
        ("(sendable? (list 1 (list +)))", "false"),
        ("(sendable? (put 'k + (make-hashmap)))", "false"),
        ("(sendable? (put + 'v (make-hashmap)))", "false")
    ] as [ValueCase])
    func sendablePredicate(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("sendable? takes one argument", arguments: ["(sendable?)", "(sendable? 1 2)"])
    func sendableArity(_ source: String) {
        expectArityFailure(source)
    }

    @Test("isSendable agrees with sendable?")
    func isSendableAccessor() {
        #expect(MyronValue.list([1, "a", .nothing]).isSendable)
        #expect(!MyronValue.list([1, .primitive(Self.primitive)]).isSendable)
    }

    private static let primitive = MyronPrimitive(
        primitiveName: "test.p",
        representations: ["p"],
        body: { _, _ in .nothing })

    @Test("the hint reads differently for a whole value and a part of one")
    func sendableHintWording() {
        let whole = MyronError.Hint.valueMustBeSendable("<procedure>", "<procedure>", .procedure)
        let part = MyronError.Hint.valueMustBeSendable("(1 <procedure>)", "<procedure>", .procedure)
        #expect(whole.description == """
            The value '<procedure>' is not sendable because it has kind 'procedure': \
            cannot send a callable, a module, or a macro
            """)
        #expect(part.description == """
            The value '(1 <procedure>)' is not sendable because it holds '<procedure>' \
            which has kind 'procedure': cannot send a callable, a module, or a macro
            """)
    }

    @Test("the error names the kind it was given")
    func sendableMessage() {
        #expect(MyronError.Reason.expectedSendable(.module).description
            == "Expected a sendable value but got kind: module")
    }

    // MARK: Sending

    @Test("send gives back nothing", arguments: [
        ("(nothing? (send self 1))", "true"),
        ("(nothing? (send self (list 1 (set 2) 'three)))", "true")
    ] as [ValueCase])
    func sendGivesNothing(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("send is an ordinary procedure", arguments: [
        ("(callable? send)", "true"),
        ("(eq (map (lambda (p) (send p 'x)) (list self self)) (list nothing nothing))", "true"),
        ("(nothing? (apply send (list self 1)))", "true")
    ] as [ValueCase])
    func sendIsFirstClass(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("send is a standard name, so it can be shadowed", arguments: [
        ("(define send 1) send", "1"),
        ("(let ((send 2)) send)", "2"),
        ("((lambda (send) send) 3)", "3")
    ] as [ValueCase])
    func sendCanBeShadowed(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("send takes a process and a value", arguments: ["(send)", "(send self)", "(send self 1 2)"])
    func sendArity(_ source: String) {
        expectArityFailure(source)
    }

    @Test("send's destination must be a process")
    func sendDestination() {
        expectFailure("(send 1 2)")
    }

    @Test("a message must be sendable, at any depth", arguments: [
        ("(send self +)", .expectedSendable(.primitive)),
        ("(send self map)", .expectedSendable(.higherOrder)),
        ("(send self (lambda (x) x))", .expectedSendable(.procedure)),
        ("(module m ()) (send self m)", .expectedSendable(.module)),
        (twice + " (send self twice)", .expectedSendable(.macro)),
        ("(send self (list 1 (list +)))", .expectedSendable(.primitive)),
        ("(send self (put 'k (lambda (x) x) (make-hashmap)))", .expectedSendable(.procedure))
    ] as [FailureCase])
    func messageMustBeSendable(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("the hint names the message and the part of it that is not sendable")
    func messageHint() throws {
        let errors = try #require(MyronSession().eval("(send self (list 1 +))").asFailure)
        #expect(errors.first?.hints == [
            .valueMustBeSendable("(1 <primitive: mathematics.add>)", "<primitive: mathematics.add>", .primitive)
        ])
    }

    // Whether a send fails never depends on whether its destination is alive.
    @Test("sending to a finished process succeeds and is dropped")
    func sendToFinished() {
        expectValue("(nothing? (send (spawn () + 1 2) 1))", "true")
        expectFailure("(send (spawn () + 1 2) +)", reason: .expectedSendable(.primitive))
    }

    // MARK: Delivery

    @Test("messages arrive in the order they were sent, from the sender")
    func selfDelivery() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let me = try Self.address(of: session)

        _ = session.eval("(send self 1) (send self '(2 two)) (send self \"three\")")

        let mailbox = try #require(runtime.mailbox(of: me))
        #expect(Self.contents(mailbox) == ["1", "(2 two)", "\"three\""])
        #expect(mailbox.map(\.source) == [me, me, me])
        #expect(mailbox.map(\.destination) == [me, me, me])
        #expect(mailbox.map(\.sequence) == [0, 1, 2])
    }

    @Test("a mailbox starts empty")
    func emptyMailbox() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        #expect(runtime.mailbox(of: try Self.address(of: session))?.isEmpty == true)
    }

    @Test("a child can send to the process that spawned it")
    func childToParent() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let parent = try Self.address(of: session)

        let child = try #require(
            session.eval(Self.echo + " (spawn (echo) echo.go self)").asSuccess?.asProcess)

        let mailbox = try #require(runtime.mailbox(of: parent))
        #expect(Self.contents(mailbox) == ["hello"])
        #expect(mailbox.first?.source == child)
        #expect(child != parent)
    }

    // The entry call runs in the child, so a primitive used as the entry
    // sends as the child, not as the parent that wrote the spawn.
    @Test("a primitive entry sends as the child")
    func primitiveEntrySendsAsChild() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let parent = try Self.address(of: session)

        let child = try #require(session.eval("(spawn () send self 'x)").asSuccess?.asProcess)

        let mailbox = try #require(runtime.mailbox(of: parent))
        #expect(Self.contents(mailbox) == ["x"])
        #expect(mailbox.first?.source == child)
    }

    @Test("sessions sharing a runtime can send to each other")
    func sessionToSession() throws {
        let runtime = MyronRuntime()
        let first = runtime.makeSession()
        let second = runtime.makeSession()
        let a = try Self.address(of: first)
        let b = try Self.address(of: second)

        try first.set("b", to: .process(b))
        _ = first.eval("(send b 'ping)")

        let mailbox = try #require(runtime.mailbox(of: b))
        #expect(Self.contents(mailbox) == ["ping"])
        #expect(mailbox.first?.source == a)
        #expect(runtime.mailbox(of: a)?.isEmpty == true)
    }

    @Test("each sender numbers its own messages")
    func perSenderSequence() throws {
        let runtime = MyronRuntime()
        let first = runtime.makeSession()
        let second = runtime.makeSession()
        let a = try Self.address(of: first)
        let b = try Self.address(of: second)

        try first.set("b", to: .process(b))
        _ = first.eval("(send b 1) (send b 2)")
        _ = second.eval("(send self 3)")
        _ = first.eval("(send b 4)")

        let mailbox = try #require(runtime.mailbox(of: b))
        #expect(Self.contents(mailbox) == ["1", "2", "3", "4"])
        #expect(mailbox.map(\.source) == [a, a, b, a])
        #expect(mailbox.map(\.sequence) == [0, 1, 0, 2])
    }

    @Test("a failed send delivers nothing")
    func failedSendDeliversNothing() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let me = try Self.address(of: session)

        _ = session.eval("(send self (list 1 +))")
        #expect(runtime.mailbox(of: me)?.isEmpty == true)
    }

    // MARK: From the Host

    @Test("a host can send from its session")
    func hostSend() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let me = try Self.address(of: session)

        try session.send(42, to: me)

        let mailbox = try #require(runtime.mailbox(of: me))
        #expect(Self.contents(mailbox) == ["42"])
        #expect(mailbox.first?.source == me)
    }

    @Test("a host cannot send what Myron code could not")
    func hostSendMustBeSendable() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let me = try Self.address(of: session)

        let error = #expect(throws: MyronError.self) {
            try session.send(.primitive(Self.primitive), to: me)
        }
        #expect(error?.reason == .expectedSendable(.primitive))
        #expect(runtime.mailbox(of: me)?.isEmpty == true)
    }

    @Test("a host send to a finished process is dropped")
    func hostSendToFinished() throws {
        let session = MyronSession()
        let child = try #require(session.eval("(spawn () + 1 2)").asSuccess?.asProcess)
        try session.send(1, to: child)
    }

    // MARK: Execution Context

    @Test("an execution context sends as its own process")
    func contextSends() throws {
        let runtime = MyronRuntime()
        let session = runtime.makeSession()
        let me = try Self.address(of: session)
        let context = MyronExecutionContext(
            location: nil,
            runtimeContext: .init(process: me, runtime: runtime))

        #expect(context.process == me)
        try context.send("hi", to: me)

        let mailbox = try #require(runtime.mailbox(of: me))
        #expect(Self.contents(mailbox) == ["\"hi\""])
        #expect(mailbox.first?.source == me)
    }

    @Test("an execution context checks what it sends")
    func contextSendMustBeSendable() {
        let context = makeExecutionContext()
        let error = #expect(throws: MyronError.self) {
            try context.send(.primitive(Self.primitive), to: context.process)
        }
        #expect(error?.reason == .expectedSendable(.primitive))
    }

}
