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
}
