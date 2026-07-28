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

    let environment: Environment
    let environmentRegistry: EnvironmentRegistry
    let evaluator: Evaluator

    public init() {
        self.environmentRegistry = EnvironmentRegistry()
        self.environment = Environment(registry: environmentRegistry)
        self.evaluator = Evaluator(registry: environmentRegistry)
    }

    deinit {
         environmentRegistry.shutdownAll()
    }

    public func eval(_ expression: String) -> Result {
        let lexer = Lexer(input: expression)
        let (tokens, lexingErrors) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (forms, parsingErrors) = parser.parse()

        guard lexingErrors.isEmpty, parsingErrors.isEmpty else {
            let errors = lexingErrors + parsingErrors
            return .failure(errors)
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
                return .failure([error])
                
            } catch {
                let error = MyronError(
                    reason: .unimplementedFeature,
                    location: form.getLocation())
                return .failure([error])
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
