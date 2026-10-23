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

        func shutdownAll() {
            environmentRegistry.shutdownAll()
        }

        deinit {
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
            guard let errorStyle = runtime?.configuration.errorStyle else {
                let explain = "missing runtime when evaluating"
                let error = MyronError(.internal(explain))
                return .failure([error])
            }

            if let error = error as? MyronError {
                let errors = [error].adorned(style: errorStyle, in: expression)
                return .failure(errors)
            }

            let message = "unhandled error type: \(error)"
            let error = MyronError(.internal(message), at: form.location)
            let errors = [error].adorned(style: errorStyle, in: expression)
            return .failure(errors)
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

extension MyronRuntime.Process {

    func entryCall(
        _ callable: MyronValue,
        with arguments: [MyronValue],
        at location: MyronLocation?
    ) throws -> MyronValue {
        return try machine.entryCall(callable, with: arguments, at: location)
    }

}
