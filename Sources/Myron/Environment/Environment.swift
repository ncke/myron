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

    func insert(_ name: String, value: MyronValue) {
        mappings[name] = value
    }
    
    func lookup(_ name: String, at location: MyronLocation?) throws -> MyronValue {
        if let match = traversingLookup(name) { return match }
        if let match = standard.lookup(name) { return match }

        let components = name.split(separator: ".", omittingEmptySubsequences: false)

        guard
            let firstName = components.first,
            let module = traversingLookup(String(firstName))
        else {
            throw MyronError(.unrecognisedSymbol, at: location)
        }

        func traverseThroughModules(
            _ value: MyronValue,
            names: ArraySlice<Substring>
        ) throws -> MyronValue {
            var traversing = value
            var remaining = names
            while true {
                guard let name = remaining.first else { return traversing }
                let module = try traversing.unwrapModule(location)

                guard let next = module[String(name)] else {
                    throw MyronError(.unrecognisedSymbol, at: location)
                        .withHint(
                            .moduleDoesNotExport(module.name, String(name)),
                            if: !name.isEmpty)
                }

                traversing = next
                remaining = remaining.dropFirst()
            }
        }

        return try traverseThroughModules(module, names: components.dropFirst())
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

    func localLookup(_ name: String) -> MyronValue? {
        return mappings[name]
    }

    var names: Set<String> {
        var ns = Set<String>(mappings.keys)
        if let outer { ns = ns.union(outer.names) }
        return ns
    }

}
