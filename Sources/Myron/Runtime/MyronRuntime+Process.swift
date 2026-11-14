import Foundation

// MARK: - MyronRuntime.Process

extension MyronRuntime {

    final class Process {

        enum CurrentEvaluation {
            case evaluation(Expression, String)
            case entry(MyronLocation?)

            var location: MyronLocation? {
                switch self {
                case .evaluation(let expression, _): return expression.location
                case .entry(let locn): return locn
                }
            }

            var representation: String? {
                switch self {
                case .evaluation(_, let rep): return rep
                case .entry: return nil
                }
            }
        }

        let identifier: MyronProcess
        private let environment: Environment
        private let environmentRegistry: EnvironmentRegistry
        private(set) weak var runtime: MyronRuntime?
        private let machine: Machine
        private var sendSequence: Int = 0
        private var messageQueue = [Message]()
        private var currentEvaluation = [CurrentEvaluation]()
        let isSpawnedProcess: Bool

        init(
            identifier: MyronProcess,
            runtime: MyronRuntime,
            configuration: MyronSessionConfiguration,
            isSpawnedProcess: Bool
        ) {
            self.identifier = identifier
            self.isSpawnedProcess = isSpawnedProcess
            self.environmentRegistry = EnvironmentRegistry()
            self.environment = Environment(
                registry: environmentRegistry,
                runtimeEnvironment: runtime.runtimeEnvironment)
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

    func eval(_ form: Expression, in representation: String) -> MyronResult {
        guard machine.state == .ready || machine.state == .evaluating else {
            let error = MyronError(.processNotReady(machine.state.description), at: form.location)
            return .failure([error])
        }

        let current = CurrentEvaluation.evaluation(form, representation)
        currentEvaluation.append(current)

        do {
            let value = try machine.eval(form)

            if machine.state == .waiting { return .waiting }

            _ = currentEvaluation.popLast()
            return .success(value)

        } catch {
            guard let current = currentEvaluation.popLast() else {
                let explain = "process '\(identifier)': missing current evaluation"
                let error = MyronError(.internal(explain))
                return .failure([error])
            }

            guard let runtime else {
                let explain = "process '\(identifier)': missing runtime with soft requirement"
                let error = MyronError(.internal(explain))
                return .failure([error])
            }

            let errorStyle = runtime.configuration.errorStyle
            if let error = error as? MyronError {
                let errors = [error].adorned(style: errorStyle, in: current.representation)
                return .failure(errors)
            }

            let explain = "process '\(identifier)': unhandled error type: \(error)"
            let error = MyronError(.internal(explain), at: current.location)
            return .failure([error].adorned(style: errorStyle, in: current.representation))
        }
    }

    func resume() -> MyronResult {
        guard machine.state == .waiting else {
            let error = MyronError(
                .processCannotResume(machine.state.description),
                at: currentEvaluation.last?.location)
            return .failure([error])
        }

        do {
            let value = try machine.resume()

            if machine.state == .waiting { return .waiting }

            _ = currentEvaluation.popLast()
            return .success(value)

        } catch {
            guard let current = currentEvaluation.popLast() else {
                let explain = "process '\(identifier)': missing current evaluation"
                let error = MyronError(.internal(explain))
                return .failure([error])
            }

            guard let runtime else {
                let explain = "process '\(identifier)': missing runtime with soft requirement"
                let error = MyronError(.internal(explain))
                return .failure([error])
            }

            let errorStyle = runtime.configuration.errorStyle
            if let error = error as? MyronError {
                let errors = [error].adorned(style: errorStyle, in: current.representation)
                return .failure(errors)
            }

            let explain = "process '\(identifier)': unhandled error type: \(error)"
            let error = MyronError(.internal(explain), at: current.location)
            return .failure([error].adorned(style: errorStyle, in: current.representation))
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
        let current = CurrentEvaluation.entry(location)
        currentEvaluation.append(current)

        return try machine.entryCall(callable, with: arguments, at: location)
    }

}

// MARK: - Message Handling

extension MyronRuntime.Process {

    var hasMessages: Bool {
        return !messageQueue.isEmpty
    }

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

// MARK: - Process State

extension MyronRuntime.Process {

    var state: Machine.State {
        return machine.state
    }

    func setState(_ state: Machine.State) {
        machine.setState(state)
    }

    func consumeFirstFromMessageQueue(where predicate: (Message) -> Bool) -> Message? {
        guard let idx = messageQueue.firstIndex(where: predicate) else { return nil }
        return messageQueue.remove(at: idx)
    }

}
