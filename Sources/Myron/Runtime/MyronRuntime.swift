import Foundation

// MARK: - Myron Runtime

public final class MyronRuntime {
    public let configuration: MyronSessionConfiguration
    private var processes = [MyronProcess: Process]()
    private var runQueue = RunQueue()
    private var counter = 0
    private var cachedResult = [MyronProcess: MyronResult]()
    let runtimeEnvironment = RuntimeEnvironment()

    public init(configuration: MyronSessionConfiguration = .standard) {
        self.configuration = configuration
    }

}

// MARK: - Process Handling

extension MyronRuntime {

    func makeProcess(isSpawned: Bool = false) -> MyronProcess {
        let identifier = MyronProcess(counter)
        counter += 1

        processes[identifier] = Process(
            identifier: identifier,
            runtime: self,
            configuration: configuration,
            isSpawnedProcess: isSpawned)

        return identifier
    }

    func shutdownProcess(_ identifier: MyronProcess) {
        if let runtimeProcess = try? getProcess(identifier) {
            runtimeProcess.shutdownAll()
            runQueue.dequeue(runtimeProcess)
        }

        processes[identifier] = nil
        cachedResult[identifier] = nil
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

        let process = makeProcess(isSpawned: true)
        let runtimeProcess = try getProcess(process)
        var shouldShutdown = true
        defer {
            if shouldShutdown { shutdownProcess(process) }
        }

        for module in context.modules {
            let result = eval(
                process,
                expression: module.definition,
                containingRepresentation: "",
                continueScheduling: false)

            switch result {
            case .failure(let errors):
                guard let firstError = errors.first else {
                    let explain = "spawning module '\(module.name)' failed with no errors"
                    throw MyronError(.internal(explain), at: module.definition.location)
                }

                throw firstError

            case .waiting:
                throw MyronError(
                    .moduleCannotWaitDuringSpawn(module.name),
                    at: context.parentLocation
                ).withHint(.receiveFromTheEntryFunction)

            default:
                continue
            }
        }

        let callable = try runtimeProcess.query(name: context.entry, at: context.parentLocation)

        do {
            _ = try runtimeProcess.entryCall(
                callable,
                with: context.arguments,
                at: context.parentLocation)
        } catch {}

        shouldShutdown = runtimeProcess.state != .waiting
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
        containingRepresentation: String,
        continueScheduling: Bool = true
    ) -> MyronResult {
        guard let runtimeProcess = processes[process] else {
            let explain = "runtime eval has no such process for identifier '\(process)'"
            let error = MyronError(.internal(explain), at: expression.location)
            return .failure([error])
        }

        cachedResult[process] = nil
        let result = runtimeProcess.eval(expression, in: containingRepresentation)

        if continueScheduling {
            runSchedule()
        }

        return result
    }

    func resume(_ process: MyronProcess) -> MyronResult {
        if let cached = cachedResult[process] {
            cachedResult[process] = nil
            runSchedule()
            return cached
        }

        guard let runtimeProcess = processes[process] else {
            let explain = "runtime resume has no such process for identifier '\(process)'"
            let error = MyronError(.internal(explain))
            return .failure([error])
        }

        let result = runtimeProcess.resume()
        runSchedule()

        return result
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

        if destinationProcess.state == .waiting {
            runQueue.enqueue(destinationProcess)
        }
    }

    func mailbox(of process: MyronProcess) -> [Message]? {
        processes[process]?.mailbox
    }

    func consumeMailboxMessage(
        _ process: MyronProcess,
        at location: MyronLocation?,
        where predicate: (Message) -> Bool
    ) throws -> Message? {
        guard let runtimeProcess = processes[process] else {
            let explain = """
            runtime consumeMailboxMessage has no such process for identifier '\(process)'
            """
            throw MyronError(.internal(explain), at: location)
        }

        return runtimeProcess.consumeFirstFromMessageQueue(where: predicate)
    }

}

// MARK: - Process State Control

extension MyronRuntime {

    func setState(
        _ process: MyronProcess,
        to state: Machine.State,
        at location: MyronLocation?
    ) throws {
        guard let runtimeProcess = processes[process] else {
            let explain = "runtime setState has no such process for identifier '\(process)'"
            throw MyronError(.internal(explain), at: location)
        }

        runtimeProcess.setState(state)
    }

}

// MARK: - Scheduling

extension MyronRuntime {

    public func hasPendingResult(for process: MyronProcess) -> Bool {
        return cachedResult[process] != nil
    }

    public var hasPendingWork: Bool {
        return !runQueue.isEmpty
    }

    public func runSchedule() {
        while let runtimeProcess = runQueue.next() {
            guard
                runtimeProcess.state == .waiting,
                runtimeProcess.hasMessages
            else {
                continue
            }

            let result = runtimeProcess.resume()

            if result != .waiting {
                if runtimeProcess.isSpawnedProcess {
                    shutdownProcess(runtimeProcess.identifier)
                } else {
                    cachedResult[runtimeProcess.identifier] = result
                }
            }
        }
    }

}

// MARK: - RunQueue

private extension MyronRuntime {

    final class RunQueue {
        private var queue = [Process]()
        private var content = Set<MyronProcess>()

        var isEmpty: Bool { return queue.isEmpty }

        func enqueue(_ process: Process) {
            guard !content.contains(process.identifier) else { return }
            queue.append(process)
            content.insert(process.identifier)
        }

        func dequeue(_ process: Process) {
            guard content.contains(process.identifier) else { return }
            queue.removeAll { queuedProcess in queuedProcess.identifier == process.identifier }
            content.remove(process.identifier)
        }

        func next() -> Process? {
            guard let process = queue.first else { return nil }
            queue = Array(queue.dropFirst())
            content.remove(process.identifier)

            return process
        }

    }

}

// MARK: - Primitive Definition

extension MyronRuntime {

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg0
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg1
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg2
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg3
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg4
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg5
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        body: @escaping MyronPrimitive.FnContextArg6
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

    public func define(
        _ name: String,
        _ signature: String? = nil,
        arity: MyronError.IntegerExpectation,
        body: @escaping MyronPrimitive.FnContextArgN
    ) throws {
        let primitive = try MyronPrimitive.define(name, signature, arity: arity, body: body)
        try runtimeEnvironment.insert(name: name, value: .primitive(primitive))
    }

}

// MARK: - Runtime Environment

extension MyronRuntime {

    final class RuntimeEnvironment {
        private var mappings = [String: MyronValue]()

        func insert(name: String, value: MyronValue) throws {
            try MyronValue.validateAsName(name, location: nil)
            mappings[name] = value
        }

        func lookup(_ name: String) -> MyronValue? {
            return mappings[name]
        }

        var names: Set<String> {
            return Set(mappings.keys)
        }

    }

}
