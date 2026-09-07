import Testing
@testable import Myron

// MARK: - Machine Tests

@Suite("Machine") struct MachineTests {

    @Test("evaluate a primitive") func evaluatePrimitive() throws {

        let registry = EnvironmentRegistry()
        let environment = Environment(registry: registry)
        let machine = Machine(environment: environment)

        let input1 = "(define x '(1 2 (a b c) 3 ())) x"
        let input2 = "(define x '(1 2 3)) x"
        let input3 = "(define x 200) x"

        let exprs = makeExpressions(input3)
        guard let exprs = exprs else {
            print("no exprs found")
            fatalError()
        }

        print("starting")
        for expr in exprs {
            let evaluation = try machine.eval(expr)
            print("evaluate to:", evaluation)
        }

        print("done")
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

