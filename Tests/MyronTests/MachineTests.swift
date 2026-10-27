import Testing
@testable import Myron

// MARK: - Machine Tests

@Suite("Machine") struct MachineTests {

    // A machine always runs on behalf of a process, so it is tested through
    // one: the runtime makes the process, and the process owns the machine.
    @Test("smoke test") func evaluatePrimitive() throws {
        let runtime = MyronRuntime()
        let process = runtime.makeProcess()
        let input = "(define x '(1 2 (a b c) 3 ())) x"

        let exprs = try #require(makeExpressions(input))

        var last: MyronResult = .nothing
        for expr in exprs {
            last = runtime.eval(process, expression: expr, containingRepresentation: input)
        }
        #expect(last.asSuccess?.description == "(1 2 (a b c) 3 ())")
    }

    @Test("a machine with no process cannot run")
    func machineNeedsProcess() throws {
        let registry = EnvironmentRegistry()
        let environment = Environment(registry: registry)
        let machine = Machine(environment: environment)
        let expr = try #require(makeExpressions("1")?.first)

        let error = #expect(throws: MyronError.self) { try machine.eval(expr) }
        guard case .internal = error?.reason else {
            Issue.record("expected an internal error, got \(String(describing: error?.reason))")
            return
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
