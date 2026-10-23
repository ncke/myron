import Testing
@testable import Myron

// MARK: - Process Values

// Nothing in the language makes a process yet, so these bind process values
// from the host: `p` and `p2` address the same process, `q` another.

@Suite("Process Values")

struct ProcessValueTests {

    private func expectProcessValue(
        _ source: String,
        _ expected: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let session = MyronSession()
        do {
            try session.set("p", to: .process(MyronProcess(3)))
            try session.set("p2", to: .process(MyronProcess(3)))
            try session.set("q", to: .process(MyronProcess(4)))
        } catch {
            Issue.record("could not bind processes: \(error)", sourceLocation: sourceLocation)
            return
        }

        switch session.eval(source) {

        case .success(let value):
            #expect(
                value.description == expected,
                "\(source) got  \(value) (expected \(expected))",
                sourceLocation: sourceLocation)

        case .failure(let errors):
            Issue.record(
                "\(source) got failure \(errors.map(\.reason)) (expected \(expected))",
                sourceLocation: sourceLocation)

        case .nothing:
            Issue.record(
                "\(source) got nothing (expected \(expected))",
                sourceLocation: sourceLocation)
        }
    }

    // MARK: Kind and Printing

    @Test("a process prints as its address and has its own kind", arguments: [
        ("p", "<process: 3>"),
        ("q", "<process: 4>"),
        ("(list p q)", "(<process: 3> <process: 4>)"),
        ("(kind p)", "\"process\"")
    ] as [ValueCase])
    func kindAndPrinting(_ c: ValueCase) {
        expectProcessValue(c.source, c.expected)
    }

    @Test("process?", arguments: [
        ("(process? p)", "true"),
        ("(process? q)", "true"),
        ("(process? 3)", "false"),
        ("(process? '(p))", "false"),
        ("(process? 'p)", "false"),
        ("(process? sqrt)", "false"),
        ("(process? (make-hashmap))", "false"),
        ("(process? nothing)", "false")
    ] as [ValueCase])
    func isProcess(_ c: ValueCase) {
        expectProcessValue(c.source, c.expected)
    }

    @Test("process? takes one argument", arguments: [
        ("(process?)", .unexpectedArity(0, .exactly(1))),
        ("(process? 1 2)", .unexpectedArity(2, .exactly(1)))
    ] as [FailureCase])
    func isProcessFailures(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: Identity

    @Test("processes compare by address", arguments: [
        ("(eq p p)", "true"),
        ("(eq p p2)", "true"),
        ("(eq p q)", "false"),
        ("(eq p 3)", "false"),
        ("(neq p q)", "true")
    ] as [ValueCase])
    func identity(_ c: ValueCase) {
        expectProcessValue(c.source, c.expected)
    }

    @Test("a process works as a set member and a hashmap key", arguments: [
        ("(length (set p p2 q))", "2"),
        ("(get p2 (put p 5 (make-hashmap)))", "5"),
        ("(get q (put p 5 (make-hashmap)))", "<nothing>")
    ] as [ValueCase])
    func collections(_ c: ValueCase) {
        expectProcessValue(c.source, c.expected)
    }

    // MARK: Swift

    @Test("a process value reads back as the process it holds")
    func swiftAccess() throws {
        let process = MyronProcess(3)
        let value = MyronValue.process(process)

        #expect(value.asProcess == process)
        #expect(try value.requireProcess() == process)
        #expect(try MyronProcess(myronValue: value) == process)
        #expect(process.myronValue == value)
        #expect(MyronValue.integer(3).asProcess == nil)
    }

    @Test("requiring a process from another kind is a type error")
    func swiftRequireFailure() {
        #expect {
            try MyronValue.integer(3).requireProcess()
        } throws: { error in
            (error as? MyronError)?.reason == .unexpectedType(.integer, [.process])
        }
    }

    @Test("process values hash by address in Swift collections")
    func swiftHashing() {
        let values: Set<MyronValue> = [
            .process(MyronProcess(3)),
            .process(MyronProcess(3)),
            .process(MyronProcess(4))
        ]
        #expect(values.count == 2)
    }

}
