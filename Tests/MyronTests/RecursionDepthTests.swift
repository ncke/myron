import Testing
@testable import Myron

// MARK: - Recursion Depth

@Suite("Recursion Depth")

// The machine holds its continuation stack on the heap, not the Swift call
// stack, so deep recursion no longer risks overflowing the test thread's
// 512 KB stack. The configured limit is what bounds it instead.

struct RecursionDepthTests {

    // Tail-recursive: the machine reuses the frame, so the stack stays flat
    // however many times this recurses.
    private static let loop = "(define (loop n) (if (== n 0) 0 (loop (- n 1))))"

    // Not tail-recursive: `n` is still needed once the recursive call returns,
    // so every level costs frames. Roughly two per level.
    private static let sum = "(define (sum n) (if (== n 0) 0 (+ n (sum (- n 1)))))"

    private static let definitions = loop + "\n" + sum

    private static func session(limit: Int?) -> MyronSession {
        MyronSession(configuration: MyronSessionConfiguration(
            errorStyle: .verbose,
            maximumStackDepth: limit))
    }

    private static func eval(_ source: String, limit: Int?) -> MyronSession.Result {
        let session = session(limit: limit)
        _ = session.eval(definitions)
        return session.eval(source)
    }

    private static func isDepthError(_ result: MyronSession.Result) -> Bool {
        guard case .failure(let errors) = result else { return false }
        return errors.contains { error in
            if case .exceededMaximumStackDepth = error.reason { return true }
            return false
        }
    }

    // MARK: - Within the Limit

    @Test("recursion within the limit succeeds")
    func withinLimit() {
        guard case .success(let value) = Self.eval("(sum 10)", limit: 200) else {
            Issue.record("(sum 10) failed under a limit of 200")
            return
        }
        #expect(value.description == "55")
    }

    @Test("tail calls do not consume depth", arguments: [
        "(loop 100000)",
        "(define (f n) (if (== n 0) 0 (let ((m (- n 1))) (f m)))) (f 100000)",
        "(define (f n) (if (== n 0) 0 (begin (f (- n 1))))) (f 100000)"
    ])
    func tailCallsAreFree(_ source: String) {
        // A limit of 10 is far below what 100,000 non-tail calls would need.
        guard case .success(let value) = Self.eval(source, limit: 10) else {
            Issue.record("\(source) failed under a limit of 10")
            return
        }
        #expect(value.description == "0")
    }

    // MARK: - Beyond the Limit

    @Test("recursion beyond the limit is an error, not a crash", arguments: [
        "(sum 100000)",
        "(define (f n) (if (== n 0) 0 (head (map f (list (- n 1)))))) (f 100000)",
        "(define (f n) (and true (if (== n 0) true (f (- n 1))))) (f 100000)",
        "(define (f n) (or false (if (== n 0) true (f (- n 1))))) (f 100000)",
        "(define (f n) (reduce (lambda (a b) (f (- n 1))) 0 '(1))) (f 100000)"
    ])
    func beyondLimit(_ source: String) {
        #expect(Self.isDepthError(Self.eval(source, limit: 200)))
    }

    @Test("deeply nested expressions count towards the limit")
    func nesting() {
        // The parser is itself recursive and unconstrained, so keep the nesting
        // shallow enough not to overflow the test thread's stack while parsing.
        let nested = String(repeating: "(+ 1 ", count: 100) + "1" + String(repeating: ")", count: 100)
        #expect(Self.isDepthError(Self.eval(nested, limit: 50)))
    }

    @Test("the error carries a location and a message")
    func errorShape() {
        guard case .failure(let errors) = Self.eval("(sum 100000)", limit: 200),
              let error = errors.first
        else {
            Issue.record("expected a failure")
            return
        }
        #expect(error.location != nil)
        #expect(error.message?.hasPrefix("ERROR: Exceeded maximum stack depth") == true)
    }

    @Test("the error reports the depth reached")
    func errorReportsDepth() {
        guard case .failure(let errors) = Self.eval("(sum 100000)", limit: 200),
              case .exceededMaximumStackDepth(let depth) = errors.first?.reason
        else {
            Issue.record("expected a depth error")
            return
        }
        #expect(depth > 200)
    }

    // MARK: - Configuration

    @Test("a session recovers after hitting the limit")
    func recovery() {
        let session = Self.session(limit: 200)
        _ = session.eval(Self.definitions)
        #expect(session.eval("(sum 100000)").isFailure)
        guard case .success(let value) = session.eval("(sum 10)") else {
            Issue.record("(sum 10) failed after a depth error")
            return
        }
        #expect(value.description == "55")
    }

    @Test("a smaller limit rejects what a larger limit allows")
    func limitIsConfigurable() {
        #expect(Self.isDepthError(Self.eval("(sum 30)", limit: 20)))
        guard case .success = Self.eval("(sum 30)", limit: 400) else {
            Issue.record("(sum 30) failed under a limit of 400")
            return
        }
    }

    @Test("a nil limit disables the check")
    func unlimited() {
        // (sum 1000) needs far more than the limits used above, but the machine
        // keeps its stack on the heap so running it unchecked is safe.
        guard case .success(let value) = Self.eval("(sum 1000)", limit: nil) else {
            Issue.record("(sum 1000) failed with no limit")
            return
        }
        #expect(value.description == "500500")
    }

    @Test("the standard configuration has a limit")
    func standardHasLimit() {
        #expect(MyronSessionConfiguration.standard.maximumStackDepth != nil)
    }

}
