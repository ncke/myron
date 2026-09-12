import Testing
@testable import Myron

// MARK: - Machine Tests

@Suite("Machine") struct MachineTests {

    @Test("smoke test") func evaluatePrimitive() throws {

        let registry = EnvironmentRegistry()
        let environment = Environment(registry: registry)
        let machine = Machine(environment: environment)
        let input = "(define x '(1 2 (a b c) 3 ())) x"


        let exprs = makeExpressions(input)
        guard let exprs = exprs else {
            Issue.record("Could not make expressions")
            return
        }

        for expr in exprs {
            let _ = try machine.eval(expr)
        }
    }

    func makeExpressions(_ input: String) -> [Expression]? {
        let (lexed, lexerErrors) = Lexer(input: input, sourceHandle: 0).tokenize()

        if !lexerErrors.isEmpty {
            print(lexerErrors)
            return nil
        }

        let (parsed, parserErrors) = Parser(tokens: lexed).parse()

        if !parserErrors.isEmpty {
            print(parserErrors)
            return nil
        }

        return parsed
    }

}
