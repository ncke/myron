import Foundation

// MARK: - MyronRuntime.Process

extension MyronRuntime {

    final class Process {
        enum State {
            case ready, evaluating, waiting, suspended
        }

        let identifier: MyronProcess
        var state: State = .ready
        private let environment: Environment
        private let environmentRegistry: EnvironmentRegistry
        private(set) weak var runtime: MyronRuntime?
        private let machine: Machine
        private var sendSequence: Int = 0
        private var messageQueue = [Message]()

        init(
            identifier: MyronProcess,
            runtime: MyronRuntime,
            configuration: MyronSessionConfiguration
        ) {
            self.identifier = identifier
            self.environmentRegistry = EnvironmentRegistry()
            self.environment = Environment(registry: environmentRegistry)
            self.runtime = runtime
            self.machine = Machine(
                environment: environment,
                maximumStackDepth: configuration.maximumStackDepth,
                maximumEvalDepth: configuration.maximumEvalDepth)

            machine.process = self
        }

        deinit {
            environmentRegistry.shutdownAll()
        }

        func shutdownAll() {
            environmentRegistry.shutdownAll()
        }

    }

}

// MARK: - Evaluation

extension MyronRuntime.Process {

    func eval(_ form: Expression, in expression: String) -> MyronResult {
        do {
            let value = try machine.eval(form)
            return .success(value)

        } catch {
            guard let runtime else {
                let explain = "process '\(identifier)': missing runtime with soft requirement"
                let error = MyronError(.internal(explain))
                return .failure([error])
            }

            let errorStyle = runtime.configuration.errorStyle
            if let error = error as? MyronError {
                let errors = [error].adorned(style: errorStyle, in: expression)
                return .failure(errors)
            }

            let explain = "process '\(identifier)': unhandled error type: \(error)"
            let error = MyronError(.internal(explain), at: form.location)
            return .failure([error].adorned(style: errorStyle, in: expression))
        }
    }

}

// MARK: - Environment Interface

extension MyronRuntime.Process {

    func insert(
        name: String,
        value: MyronValue,
        location: MyronLocation?
    ) throws {
        return try environment.insert(name, value: value, location: location)
    }

    func query(name: String, at location: MyronLocation? = nil) throws -> MyronValue {
        return try environment.lookup(name, at: location)
    }

    var names: Set<String> {
        return environment.names
    }

    func prepareEnvironment() {
        environmentRegistry.resetTidyTrigger()
    }

    func tidyEnvironment() {
        environmentRegistry.tidy()
    }

}

// MARK: - Entry Call

extension MyronRuntime.Process {

    func entryCall(
        _ callable: MyronValue,
        with arguments: [MyronValue],
        at location: MyronLocation?
    ) throws -> MyronValue {
        return try machine.entryCall(callable, with: arguments, at: location)
    }

}

// MARK: - Message Handling

extension MyronRuntime.Process {

    func getNextSendSequence() -> Int {
        let sequence = sendSequence
        sendSequence += 1
        return sequence
    }

    func enqueueMessage(_ message: Message) {
        messageQueue.append(message)
    }

    var mailbox: [Message] {
        messageQueue
    }

}

// MARK: - Runtime Helper

extension MyronRuntime.Process {

    func getRuntime(at location: MyronLocation?) throws -> MyronRuntime {
        guard let runtime else {
            let explain = "process '\(identifier)': missing runtime with hard requirement"
            throw MyronError(.internal(explain), at: location)
        }

        return runtime
    }
    
}
