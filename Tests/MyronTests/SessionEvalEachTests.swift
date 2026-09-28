import Testing
import Myron // Imported without @testable to exercise only public API.

// MARK: - Session Eval Each

@Suite("Session Eval Each")

struct SessionEvalEachTests {

    // The printed form of each result, or the reason for each failure, so a
    // test can state a whole run at once.
    private static func outcomes(_ results: [MyronFormResult]) -> [String] {
        results.map { formResult in
            switch formResult.result {
            case .success(let value): return value.description
            case .failure(let errors): return "failure: \(errors.map(\.reason))"
            case .nothing: return "nothing"
            }
        }
    }

    // The source text each result's location covers.
    private static func spans(_ results: [MyronFormResult], in source: String) -> [String?] {
        results.map { formResult in
            formResult.location.map { location in
                String(source.dropFirst(location.lowerBound).prefix(location.count))
            }
        }
    }

    // MARK: Results

    @Test("every form gives a result, in order")
    func resultPerForm() {
        let results = MyronSession().evalEach("(+ 1 2) \"a\" (list 3 4)")
        #expect(Self.outcomes(results) == ["3", "\"a\"", "(3 4)"])
    }

    @Test("source with no forms gives no results")
    func noForms() {
        #expect(MyronSession().evalEach("").isEmpty)
        #expect(MyronSession().evalEach("; only a comment\n").isEmpty)
    }

    @Test("a later form sees an earlier form's definition")
    func sharedEnvironment() {
        let results = MyronSession().evalEach("(define x 10) (+ x 1)")
        #expect(Self.outcomes(results).last == "11")
    }

    @Test("definitions persist in the session afterwards")
    func definitionsPersist() {
        let session = MyronSession()
        _ = session.evalEach("(define (sq n) (* n n))")
        #expect(session.eval("(sq 7)").asSuccess?.asInteger == 49)
    }

    // MARK: Failures

    @Test("a failing form does not stop the forms after it")
    func failureContinues() {
        let results = MyronSession().evalEach("(+ 1 1) (/ 1 0) (+ 2 2)")
        #expect(Self.outcomes(results) == ["2", "failure: [Division by zero]", "4"])
    }

    @Test("eval still stops at the first failing form")
    func evalStillStops() {
        let session = MyronSession()
        #expect(session.eval("(/ 1 0) (define x 1)").isFailure)
        #expect(session.query("x") == nil)
    }

    @Test("a failure is rendered against the whole source, with its caret")
    func failureRendered() throws {
        let results = MyronSession().evalEach("(+ 1 1)\n(car 1)")
        let error = try #require(results.last?.result.asFailure?.first)
        #expect(error.message == "ERROR: Unrecognised symbol\n(car 1)\n ^^^")
    }

    @Test("source that does not parse gives a single failure and evaluates nothing")
    func parseFailure() throws {
        let session = MyronSession()
        let results = session.evalEach("(define x 1) (+ 1")

        #expect(results.count == 1)
        let error = try #require(results.first?.result.asFailure?.first)
        #expect(error.reason == .unmatchedParenthesis)
        #expect(results.first?.location == error.location)
        #expect(session.query("x") == nil)
    }

    // MARK: Callbacks

    // A host primitive and both callbacks write to one log, so the log shows
    // whether each form's own output falls between its two callbacks.
    private final class Log: @unchecked Sendable {
        var entries = [String]()
    }

    @Test("the callbacks bracket each form's evaluation")
    func callbacksBracketForms() throws {
        let session = MyronSession()
        let log = Log()
        try session.define("note") { v in
            log.entries.append("note \(v)")
            return MyronValue.nothing
        }

        let source = "(note 1) (+ 1 1)"
        _ = session.evalEach(
            source,
            willEvaluate: { location in
                log.entries.append("will \(location.map { String(source.dropFirst($0.lowerBound).prefix($0.count)) } ?? "")")
            },
            didEvaluate: { formResult in
                log.entries.append("did \(formResult.result.asSuccess?.description ?? "")")
            })

        #expect(log.entries == [
            "will (note 1)", "note 1", "did <nothing>",
            "will (+ 1 1)", "did 2",
        ])
    }

    @Test("a parse failure reaches didEvaluate alone")
    func parseFailureCallbacks() {
        let log = Log()
        let results = MyronSession().evalEach(
            "(+ 1",
            willEvaluate: { _ in log.entries.append("will") },
            didEvaluate: { formResult in
                log.entries.append(formResult.result.isFailure ? "failed" : "did")
            })

        #expect(log.entries == ["failed"])
        #expect(results.count == 1)
    }

    // MARK: Locations

    @Test("each location covers its form's source text")
    func locationsCoverForms() {
        let source = "(define (sq n)\n  (* n n))\n'x 42 \"s\" (sq 3)"
        let results = MyronSession().evalEach(source)
        #expect(Self.spans(results, in: source)
            == ["(define (sq n)\n  (* n n))", "'x", "42", "\"s\"", "(sq 3)"])
    }

}
