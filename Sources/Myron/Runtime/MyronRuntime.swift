import Foundation

// MARK: - Myron Runtime

public final class MyronRuntime {
    public let configuration: MyronSessionConfiguration
    private var processes = [MyronProcess: Process]()
    private var counter = 0

    public init(configuration: MyronSessionConfiguration = .standard) {
        self.configuration = configuration
    }

}

// MARK: - Process Handling

extension MyronRuntime {

    func makeProcess() -> MyronProcess {
        let identifier = MyronProcess(counter)
        counter += 1

        processes[identifier] = Process(
            identifier: identifier,
            runtime: self,
            configuration: configuration)

        return identifier
    }

    func shutdownProcess(_ identifier: MyronProcess) throws {
        let runtimeProcess = try getProcess(identifier)
        runtimeProcess.shutdownAll()
        processes[identifier] = nil
    }

    var processCount: Int {
        processes.count
    }

    private func getProcess(
        _ identifier: MyronProcess,
        location: MyronLocation? = nil
    ) throws -> MyronRuntime.Process {
        guard let process = processes[identifier] else {
            let explain = "runtime has no such process for identifier '\(identifier)'"
            throw MyronError(.internal(explain), at: location)
        }

        return process
    }

}

// MARK: - Spawning

extension MyronRuntime {

    func spawn(using context: SpawningContext) throws -> MyronValue {
        let entrySplits = context.entry.split(separator: ".", maxSplits: 1)
        if entrySplits.count > 1, let firstSplit = entrySplits.first {
            let isModulePresent = context.modules.contains { module in module.name == firstSplit }
            guard isModulePresent else {
                let unrecognisedModule = String(firstSplit)
                throw MyronError(.unrecognisedSymbol, at: context.parentLocation)
                    .withHint(.spawnCannotEnterThroughUnrecognisedModule(unrecognisedModule))
            }
        }

        for argument in context.arguments {
            do {
                try argument.validateAsSendable(context.parentLocation)
            } catch let error as MyronError {
                throw error.withHint(.spawnCannotEnterWithNonSendableArgument)
            }
        }

        let process = makeProcess()

        for module in context.modules {
            let result = eval(process, expression: module.definition, containingRepresentation: "")

            switch result {
            case .failure(let errors):
                try shutdownProcess(process)

                guard let firstError = errors.first else {
                    let explain = "spawning module '\(module.name)' failed with no errors"
                    throw MyronError(.internal(explain), at: module.definition.location)
                }

                throw firstError
            default:
                continue
            }
        }

        defer { try? shutdownProcess(process) }

        let runtimeProcess = try getProcess(process)
        let callable = try runtimeProcess.query(name: context.entry, at: context.parentLocation)

        do {
            _ = try runtimeProcess.entryCall(
                callable,
                with: context.arguments,
                at: context.parentLocation)
        } catch {}

        return .process(process)
    }

}

// MARK: - Spawning Context

class SpawningContext {
    let parentEnvironment: Environment
    let parentLocation: MyronLocation?
    let entry: String
    private(set) var modules = [MyronModule]()
    private(set) var arguments = [MyronValue]()

    init(
        parentEnvironment: Environment,
        parentLocation: MyronLocation?,
        entry: String
    ) {
        self.parentEnvironment = parentEnvironment
        self.parentLocation = parentLocation
        self.entry = entry
    }

    func addModule(_ module: MyronModule) {
        modules.append(module)
    }

    func addArgument(_ argument: MyronValue) {
        arguments.append(argument)
    }

}

// MARK: - Process Interface

extension MyronRuntime {

    func eval(
        _ process: MyronProcess,
        expression: Expression,
        containingRepresentation: String
    ) -> MyronResult {
        guard let runtimeProcess = processes[process] else {
            let explain = "runtime has no such process for identifier '\(process)'"
            let error = MyronError(.internal(explain), at: expression.location)
            return .failure([error])
        }

        return runtimeProcess.eval(expression, in: containingRepresentation)
    }

    func insert(
        _ process: MyronProcess,
        name: String,
        value: MyronValue,
        location: MyronLocation?
    ) throws {
        let runtimeProcess = try getProcess(process)
        try runtimeProcess.insert(name: name, value: value, location: location)
    }

    func query(
        _ process: MyronProcess,
        name: String,
        location: MyronLocation?
    ) throws -> MyronValue? {
        let runtimeProcess = try getProcess(process)
        return try runtimeProcess.query(name: name)
    }

    func names(_ process: MyronProcess) throws -> Set<String> {
        let runtimeProcess = try getProcess(process)
        return runtimeProcess.names
    }

    func prepareEnvironment(_ process: MyronProcess) {
        guard let runtimeProcess = try? getProcess(process) else { return }
        runtimeProcess.prepareEnvironment()
    }

    func tidyEnvironment(_ process: MyronProcess) {
        guard let runtimeProcess = try? getProcess(process) else { return }
        runtimeProcess.tidyEnvironment()
    }

}

// MARK: - Create Session

extension MyronRuntime {

    public func makeSession() -> MyronSession {
        MyronSession(runtime: self)
    }

}

// MARK: - Message Handling

extension MyronRuntime {

    func send(
        source: MyronProcess,
        destination: MyronProcess,
        content: MyronValue,
        location: MyronLocation?
    ) throws {
        try content.validateAsSendable(location)

        guard
            let sourceProcess = processes[source],
            let destinationProcess = processes[destination]
        else { return }

        let sequence = sourceProcess.getNextSendSequence()
        let message = Message(
            source: source,
            destination: destination,
            sequence: sequence,
            content: content)

        destinationProcess.enqueueMessage(message)
    }

    func mailbox(of process: MyronProcess) -> [Message]? {
        processes[process]?.mailbox
    }

}
