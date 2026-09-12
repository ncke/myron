import Foundation

// MARK: - Environment

final class Environment {
    private var mappings: [String: MyronValue] = [:]
    private var outer: Environment?
    private(set) weak var registry: EnvironmentRegistry?

    init(registry: EnvironmentRegistry) {
        self.outer = nil
        self.registry = registry
        registry.register(self)
    }

    init(outer: Environment, at location: MyronLocation?) throws {
        self.outer = outer
        guard let registry = outer.registry else {
            throw MyronError(.containingEnvironmentNoLongerExists, at: location)
        }

        self.registry = outer.registry
        registry.register(self)
    }

    func shutdown() {
        mappings = [:]
    }

    func insert(_ name: String, value: MyronValue) {
        mappings[name] = value
    }

    func lookup(_ name: String) -> MyronValue? {
        return mappings[name]
        ?? outer?.lookup(name)
        ?? standardLookup(name)
    }

    var names: Set<String> {
        var ns = Set<String>(mappings.keys)
        if let outer { ns = ns.union(outer.names) }
        return ns
    }

}
