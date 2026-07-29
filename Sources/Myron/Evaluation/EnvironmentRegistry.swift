import Foundation

// MARK: - EnvironmentRegistry

final class EnvironmentRegistry {

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
        tidy()
    }

    func shutdownAll() {
        for entry in register {
            guard let environment = entry.environment else { continue }
            environment.shutdown()
        }
    }

    private func tidy() {
        let survivors: [EnvironmentEntry] = register.filter {
            entry in entry.environment != nil
        }

        register = survivors
    }

}
