import Foundation

// MARK: - Environment

public final class Environment {
    private var mappings: [String: Value] = [:]
    private var outer: Environment?
    private(set) weak var registry: EnvironmentRegistry!

    init(registry: EnvironmentRegistry) {
        self.outer = nil
        self.registry = registry
        self.registry.register(self)
    }

    init(outer: Environment) {
        self.outer = outer
        self.registry = outer.registry
        self.registry.register(self)
    }

    func shutdown() {
        mappings = [:]
    }

    func insert(_ name: String, value: Value) {
        mappings[name] = value
    }

    func lookup(_ name: String) -> Value? {
        return mappings[name]
            ?? outer?.lookup(name)
            ?? standardLookup(name)
    }

}
