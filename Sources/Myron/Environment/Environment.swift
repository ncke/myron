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
    
    func lookup(_ name: String) -> MyronValue? {
        if let match = traversingLookup(name) { return match }
        return standard.lookup(name)
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

    var names: Set<String> {
        var ns = Set<String>(mappings.keys)
        if let outer { ns = ns.union(outer.names) }
        return ns
    }

}
