import Foundation

public extension MyronSession.Result {

    var isFailure: Bool {
        switch self {
        case .failure: return true
        default: return false
        }
    }

}

// MARK: - MyronSession

public final class MyronSession {

    public enum Result {
        case success(Value)
        case failure([MyronError])
        case nothing
    }

    let configuration: MyronSessionConfiguration
    let environment: Environment
    let environmentRegistry: EnvironmentRegistry
    let evaluator: Evaluator

    public init(configuration: MyronSessionConfiguration = .standard) {
        self.configuration = configuration
        self.environmentRegistry = EnvironmentRegistry()
        self.environment = Environment(registry: environmentRegistry)
        self.evaluator = Evaluator()
    }

    deinit {
         environmentRegistry.shutdownAll()
    }

    public func eval(
        _ expression: String,
        sourceHandle: Int? = nil
    ) -> Result {
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

        func caughtEval(_ form: Expression) -> Result {
            do {
                let value = try evaluator.eval(form, environment: environment)
                return .success(value)

            } catch let error as MyronError {
                let adornedError = adornErrorIfNecessary(error, in: expression)
                return .failure([adornedError])

            } catch {
                let error = MyronError(.internalError, at: form.getLocation())
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
