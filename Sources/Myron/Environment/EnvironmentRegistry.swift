import Foundation

// MARK: - EnvironmentRegistry

final class EnvironmentRegistry {
    static let defaultTidyTrigger = 120
    private var tidyTrigger = EnvironmentRegistry.defaultTidyTrigger

    private class EnvironmentEntry {
        weak var environment: Environment?

        init(environment: Environment) {
            self.environment = environment
        }
    }

    private var register: [EnvironmentEntry] = []

    func register(_ environment: Environment) {
        let entry = EnvironmentEntry(environment: environment)
        register.append(entry)
        if register.count >= tidyTrigger { tidy() }
    }

    func shutdownAll() {
        for entry in register {
            guard let environment = entry.environment else { continue }
            environment.shutdown()
        }
    }

    func tidy() {
        register = register.filter { reg in reg.environment != nil }
        tidyTrigger = register.count < 100 ? 120 : Int(Double(register.count) * 1.2)
    }

    func resetTidyTrigger() {
        tidyTrigger = EnvironmentRegistry.defaultTidyTrigger
    }

}
