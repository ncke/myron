import Foundation

// MARK: - MyronSession

public final class MyronSession {
    private let configuration: MyronSessionConfiguration
    private let environment: Environment
    private let environmentRegistry: EnvironmentRegistry
    private let machine: Machine

    public init(configuration: MyronSessionConfiguration = .standard) {
        self.configuration = configuration
        self.environmentRegistry = EnvironmentRegistry()
        self.environment = Environment(registry: environmentRegistry)
        self.machine = Machine(
            environment: environment,
            maximumStackDepth: configuration.maximumStackDepth)
    }

    deinit {
         environmentRegistry.shutdownAll()
    }

    public func eval(
        _ expression: String,
        sourceHandle: Int? = nil
    ) -> MyronResult {
        defer { environmentRegistry.tidy() }
        environmentRegistry.resetTidyTrigger()
        let lexer = Lexer(input: expression, sourceHandle: sourceHandle)
        let (tokens, lexingErrors) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (forms, parsingErrors) = parser.parse()

        guard lexingErrors.isEmpty, parsingErrors.isEmpty else {
            let errors = lexingErrors + parsingErrors
            let adornedErrors = adornErrorsIfNecessary(errors, in: expression)
            return .failure(adornedErrors)
        }

        let silentForms = forms.dropLast()

        guard let lastForm = forms.last else {
            return .nothing
        }

        func caughtEval(_ form: Expression) -> MyronResult {
            do {
                let value = try machine.eval(form)
                return .success(value)

            } catch let error as MyronError {
                let adornedError = adornErrorIfNecessary(error, in: expression)
                return .failure([adornedError])

            } catch {
                let message = "unhandled error type: \(error)"
                let error = MyronError(.internalError(message), at: form.location)
                let adornedError = adornErrorIfNecessary(error, in: expression)
                return .failure([adornedError])
            }
        }

        for form in silentForms {
            let result = caughtEval(form)
            if result.isFailure {
                return result
            }
        }

        let result = caughtEval(lastForm)
        return result
    }

}

// MARK: - Error Messages

private extension MyronSession {

    func adornErrorsIfNecessary(_ errors: [MyronError], in expression: String) -> [MyronError] {
        errors.map { error in adornErrorIfNecessary(error, in: expression) }
    }

    func adornErrorIfNecessary(_ error: MyronError, in expression: String) -> MyronError {
        switch configuration.errorStyle {
        case .terse: return error
        case .verbose: return error.withMessage(in: expression)
        }
    }

}
