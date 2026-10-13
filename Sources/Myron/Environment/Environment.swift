import Foundation

// MARK: - Environment

final class Environment {
    private var mappings: [String: MyronValue] = [:]
    private var outer: Environment?
    private let standard: StandardEnvironment
    private(set) weak var registry: EnvironmentRegistry?

    init(registry: EnvironmentRegistry) {
        self.outer = nil
        self.registry = registry
        self.standard = StandardEnvironment()
        registry.register(self)
    }

    init(outer: Environment, at location: MyronLocation?) throws {
        self.outer = outer
        guard let registry = outer.registry else {
            throw MyronError(.containingEnvironmentNoLongerExists, at: location)
        }

        self.standard = outer.standard
        self.registry = outer.registry
        registry.register(self)
    }

    func shutdown() {
        mappings = [:]
    }

    func insert(_ name: String, value: MyronValue, location: MyronLocation?) throws {
        try MyronValue.validateAsName(name, location: location)
        mappings[name] = value
    }

    func optionalLookup(_ name: String, at location: MyronLocation?) -> MyronValue? {
        let result = handleLookup(name, at: location)
        switch result {
        case .success(let value): return value
        case .failure: return nil
        }
    }

    func lookup(_ name: String, at location: MyronLocation?) throws -> MyronValue {
        let result = handleLookup(name, at: location)
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func handleLookup(
        _ name: String,
        at location: MyronLocation?,
    ) -> Result<MyronValue, Error> {
        if let match = traversingLookup(name) { return .success(match) }
        if let match = standard.lookup(name) { return .success(match) }

        if name.hasSuffix("..."), name.count > 3 {
            let stem = String(name.dropLast(3))
            if traversingLookup(stem) != nil || standard.lookup(stem) != nil {
                let error = MyronError(.unrecognisedSymbol, at: location)
                    .withHint(.nameWasWrittenWithEllipsis(stem))
                return .failure(error)
            }
        }

        let components = name.split(separator: ".", omittingEmptySubsequences: false)

        guard
            let firstName = components.first,
            let module = traversingLookup(String(firstName))
        else {
            return .failure(MyronError(.unrecognisedSymbol, at: location))
        }

        return traverseThroughModules(module, names: components.dropFirst(), at: location)
    }

    private func traversingLookup(_ name: String) -> MyronValue? {
        var lookupEnvironment: Environment? = self
        while lookupEnvironment != nil {
            if let match = lookupEnvironment?.mappings[name] {
                return match
            }
            
            lookupEnvironment = lookupEnvironment?.outer
        }
        
        return nil
    }

    private func traverseThroughModules(
        _ value: MyronValue,
        names: ArraySlice<Substring>,
        at location: MyronLocation?
    ) -> Result<MyronValue, Error> {
        var traversing = value
        var remaining = names
        while true {
            guard let name = remaining.first else { return .success(traversing) }

            guard let module = traversing.asModule else {
                let reason = MyronError.Reason.unexpectedType(traversing.kind, [.module])
                let error = MyronError(reason, at: location)
                return .failure(error)
            }

            guard let next = module[String(name)] else {
                let hint = MyronError.Hint.moduleDoesNotExport(module.name, String(name))
                let error = MyronError(.unrecognisedSymbol, at: location)
                    .withHint(hint, if: !name.isEmpty)
                return .failure(error)
            }

            traversing = next
            remaining = remaining.dropFirst()
        }
    }

    func localLookup(_ name: String) -> MyronValue? {
        return mappings[name]
    }

    var names: Set<String> {
        var ns = Set<String>(mappings.keys)
        if let outer { ns = ns.union(outer.names) }
        return ns
    }

}
