import Testing
@testable import Myron

// MARK: - Recursion Depth

@Suite("Recursion Depth")

// Note: test thread has a 512 KB stack, so recursion overflows quickly.

struct RecursionDepthTests {

    private static let loop = "(define (loop n) (if (== n 0) 0 (loop (- n 1))))"

    private static func session(limit: Int?) -> MyronSession {
        MyronSession(configuration: MyronSessionConfiguration(
            errorStyle: .verbose,
            maximumRecursionDepth: limit))
    }

    private static func eval(_ source: String, limit: Int?) -> MyronSession.Result {
        let session = session(limit: limit)
        _ = session.eval(loop)
        return session.eval(source)
    }

    private static func reasons(_ result: MyronSession.Result) -> [MyronError.Reason] {
        if case .failure(let errors) = result { return errors.map(\.reason) }
        return []
    }

    @Test("recursion within the limit succeeds")
    func withinLimit() {
        guard case .success(let value) = Self.eval("(loop 10)", limit: 200) else {
            Issue.record("(loop 10) failed under a limit of 200")
            return
        }
        #expect(value.description == "0")
    }

    @Test("recursion beyond the limit is an error, not a crash", arguments: [
        "(loop 100000)",
        "(define (f n) (if (== n 0) 0 (head (map f (list (- n 1)))))) (f 100000)",
        "(define (f n) (if (== n 0) 0 (let ((m (- n 1))) (f m)))) (f 100000)",
        "(define (f n) (if (== n 0) 0 (begin (f (- n 1))))) (f 100000)",
        "(define (f n) (and true (if (== n 0) true (f (- n 1))))) (f 100000)",
        "(define (f n) (or false (if (== n 0) true (f (- n 1))))) (f 100000)",
        "(define (f n) (reduce (lambda (a b) (f (- n 1))) 0 '(1))) (f 100000)",
        "(define (f) (f)) (f)"
    ])
    func beyondLimit(_ source: String) {
        #expect(Self.reasons(Self.eval(source, limit: 200)) == [.reachedMaximumRecursionDepth])
    }

    @Test("deeply nested expressions count towards the limit")
    func nesting() {
        // The parser is itself recursive and unconstrained, so can overflow
        // the test thread's stack.
        let nested = String(repeating: "(+ 1 ", count: 100) + "1" + String(repeating: ")", count: 100)
        #expect(Self.reasons(Self.eval(nested, limit: 50)) == [.reachedMaximumRecursionDepth])
    }

    @Test("the error carries a location and a message")
    func errorShape() {
        guard case .failure(let errors) = Self.eval("(loop 100000)", limit: 200),
              let error = errors.first
        else {
            Issue.record("expected a failure")
            return
        }
        #expect(error.location != nil)
        #expect(error.message?.hasPrefix("ERROR: Reached maximum recursion depth") == true)
    }

    @Test("a session recovers after hitting the limit")
    func recovery() {
        let session = Self.session(limit: 200)
        _ = session.eval(Self.loop)
        #expect(session.eval("(loop 100000)").isFailure)
        guard case .success(let value) = session.eval("(loop 10)") else {
            Issue.record("(loop 10) failed after a depth error")
            return
        }
        #expect(value.description == "0")
    }

    @Test("a smaller limit rejects what a larger limit allows")
    func limitIsConfigurable() {
        #expect(Self.reasons(Self.eval("(loop 30)", limit: 50)) == [.reachedMaximumRecursionDepth])
        guard case .success = Self.eval("(loop 30)", limit: 400) else {
            Issue.record("(loop 30) failed under a limit of 400")
            return
        }
    }

    @Test("a nil limit disables the check")
    func unlimited() {
        // (loop 30) is rejected by a limit of 50 but is well within the
        // thread's stack, so it is safe to run unchecked.
        guard case .success(let value) = Self.eval("(loop 30)", limit: nil) else {
            Issue.record("(loop 30) failed with no limit")
            return
        }
        #expect(value.description == "0")
    }

    @Test("the standard configuration has a limit")
    func standardHasLimit() {
        #expect(MyronSessionConfiguration.standard.maximumRecursionDepth != nil)
    }

}
