import Testing
@testable import Myron

// MARK: - Cond

@Suite("Cond")

struct CondTests {

    private static func eval(_ source: String, limit: Int?) -> MyronResult {
        MyronSession(configuration: MyronSessionConfiguration(
            errorStyle: .verbose,
            maximumStackDepth: limit)).eval(source)
    }

    private static func isDepthError(_ result: MyronResult) -> Bool {
        guard case .failure(let errors) = result else { return false }
        return errors.contains { error in
            if case .exceededMaximumStackDepth = error.reason { return true }
            return false
        }
    }

    // MARK: - Selection

    @Test("cond yields the body of the first matching clause", arguments: [
        ("(cond (true 1))", "1"),
        ("(cond (false 1) (true 2))", "2"),
        ("(cond ((== 1 2) \"a\") ((== 2 2) \"b\") (true \"c\"))", "\"b\""),
        ("(cond ((== 1 2) \"a\") ((== 2 3) \"b\") (true \"c\"))", "\"c\""),
        ("(cond (true 1) (true 2))", "1"),
        ("(cond (true (cond (false 1) (true 2))))", "2"),
        ("(+ 1 (cond (false 1) (true 2)))", "3")
    ] as [ValueCase])
    func selection(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a matching clause evaluates every body and yields the last", arguments: [
        ("(cond (true 1 2 3))", "3"),
        ("(cond (false 1) (true 1 2 3))", "3"),
        ("(cond (true (define q 5) q))", "5")
    ] as [ValueCase])
    func multipleBodies(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("cond yields nothing when it selects no body", arguments: [
        // No clause matches.
        ("(cond (false 1))", "<nothing>"),
        ("(cond (false 1) (false 2))", "<nothing>"),
        // A clause matches but carries no body.
        ("(cond (true))", "<nothing>"),
        ("(cond (false 1) (true))", "<nothing>")
    ] as [ValueCase])
    func nothingCases(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a clause body sees the enclosing environment")
    func environment() {
        expectValue("(define x 5) (cond ((> x 0) x))", "5")
        expectValue("(define (f n) (cond ((> n 0) n) (true 0))) (f 7)", "7")
    }

    // MARK: - Laziness

    @Test("tests after the first match are not evaluated")
    func laterTestsAreNotEvaluated() {
        // `junk` is unbound, reaching its clause would be an unrecognised symbol.
        expectValue("(cond (true 1) (junk 2))", "1")
    }

    @Test("bodies of unmatched clauses are not evaluated")
    func unmatchedBodiesAreNotEvaluated() {
        expectValue("(cond (false junk) (true 1))", "1")
    }

    @Test("tests are evaluated in order until one matches")
    func testsRunInOrder() {
        // The second test would fail on a type error if it were reached.
        expectValue("(cond (true 1) ((+ 1 \"x\") 2))", "1")
    }

    // MARK: - Tail Calls

    @Test("a single-body clause leaves its body in tail position")
    func singleBodyIsTailCall() {
        let source = """
            (define (f n) (cond ((== n 0) 0) (true (f (- n 1)))))
            (f 100000)
            """
        guard case .success(let value) = Self.eval(source, limit: 20) else {
            Issue.record("100000 tail calls through cond exceeded a limit of 20")
            return
        }
        #expect(value.description == "0")
    }

    @Test("a multi-body clause leaves its last body in tail position")
    func lastBodyIsTailCall() {
        let source = """
            (define (f n) (cond ((== n 0) 0) (true 1 2 (f (- n 1)))))
            (f 100000)
            """
        guard case .success(let value) = Self.eval(source, limit: 20) else {
            Issue.record("100000 tail calls through a multi-body clause exceeded a limit of 20")
            return
        }
        #expect(value.description == "0")
    }

    @Test("a clause body that is not a tail call still consumes depth")
    func nonTailBodyConsumesDepth() {
        let source = """
            (define (f n) (cond ((== n 0) 0) (true (+ 0 (f (- n 1))))))
            (f 100000)
            """
        #expect(Self.isDepthError(Self.eval(source, limit: 200)))
    }

    // MARK: - Errors

    @Test("cond errors", arguments: [
        // At least one clause is required.
        ("(cond)", .unexpectedArity(0, .atLeast(1))),
        // A clause must be a list...
        ("(cond 5)", .unexpectedType(.integer, [.list])),
        ("(cond \"x\")", .unexpectedType(.string, [.list])),
        ("(cond (false 1) 5)", .unexpectedType(.integer, [.list])),
        // ...and must carry a test.
        ("(cond ())", .unexpectedArity(0, .atLeast(1))),
        ("(cond (false 1) ())", .unexpectedArity(0, .atLeast(1))),
        // A test must be a boolean.
        ("(cond (1 2))", .unexpectedType(.integer, [.boolean])),
        ("(cond (false 1) (\"x\" 2))", .unexpectedType(.string, [.boolean])),
        // Errors inside a reached clause propagate.
        ("(cond (false 1) (junk 2))", .unrecognisedSymbol),
        ("(cond (true (/ 1 0)))", .divisionByZero)
    ] as [FailureCase])
    func condErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a malformed clause carries the location of the clause, not the form")
    func errorLocation() {
        // Both the first clause and a later one should point at the clause
        // itself, so the caret lands on the offending text.
        for source in ["(cond ())", "(cond (false 1) ())"] {
            guard case .failure(let errors) = MyronSession().eval(source),
                  let location = errors.first?.location
            else {
                Issue.record("\(source) did not fail with a located error")
                continue
            }
            let start = source.index(source.startIndex, offsetBy: location.lowerBound)
            let end = source.index(source.startIndex, offsetBy: location.upperBound)
            #expect(String(source[start..<end]) == "()")
        }
    }

    // MARK: - Clause Validation

    @Test("clauses after the match are not checked for shape")
    func laterClausesAreNotValidated() {
        expectValue("(cond (true 1) 5)", "1")
        expectValue("(cond (true 1) ())", "1")
    }

}
