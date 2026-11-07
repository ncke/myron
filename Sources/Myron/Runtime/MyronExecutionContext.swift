import Foundation

// MARK: - Myron Execution Context

public struct MyronExecutionContext {
    struct RuntimeContext {
        let process: MyronProcess
        let runtime: MyronRuntime
    }

    public let location: MyronLocation?
    private let runtimeContext: RuntimeContext

    init(
        location: MyronLocation?,
        runtimeContext: RuntimeContext
    ) {
        self.location = location
        self.runtimeContext = runtimeContext
    }

    public var process: MyronProcess { runtimeContext.process }

    public func send(_ content: MyronValue, to destination: MyronProcess) throws {
        try runtimeContext.runtime.send(
            source: runtimeContext.process,
            destination: destination,
            content: content,
            location: location)
    }

    func setProcessState(to state: Machine.State) throws {
        try runtimeContext.runtime.setState(runtimeContext.process, to: state, at: location)
    }

    func consumeMessage(where predicate: (Message) -> Bool) throws -> Message? {
        try runtimeContext.runtime.consumeMailboxMessage(
            runtimeContext.process,
            at: location,
            where: predicate)
    }

}
