import Testing
@testable import Myron

// MARK: - Try and Raise

@Suite("Try and Raise")

struct TryRaiseTests {

    private static func eval(_ source: String, limit: Int?) -> MyronResult {
        MyronSession(configuration: MyronSessionConfiguration(
            errorStyle: .verbose,
            maximumStackDepth: limit)).eval(source)
    }

    // MARK: - Raise

    @Test("an uncaught raise fails with its message")
    func uncaughtRaise() {
        expectFailure("(raise \"boom\")", reason: .raised("boom"))
        expectFailure("(define (f) (raise \"deep\")) (f)", reason: .raised("deep"))
    }

    @Test("an uncaught raise carries the location of the raising call")
    func uncaughtRaiseLocation() {
        let source = "(+ 1 (raise \"boom\"))"
        guard case .failure(let errors) = MyronSession().eval(source),
              let location = errors.first?.location
        else {
            Issue.record("\(source) did not fail with a located error")
            return
        }
        let start = source.index(source.startIndex, offsetBy: location.lowerBound)
        let end = source.index(source.startIndex, offsetBy: location.upperBound)
        #expect(String(source[start..<end]) == "(raise \"boom\")")
    }

    @Test("raise takes exactly one string", arguments: [
        ("(raise 1)", .unexpectedType(.integer, [.string])),
        ("(raise 'boom)", .unexpectedType(.symbol, [.string])),
        ("(raise)", .unexpectedArity(0, .exactly(1))),
        ("(raise \"a\" \"b\")", .unexpectedArity(2, .exactly(1)))
    ] as [FailureCase])
    func raiseArguments(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("a raised reason describes its message")
    func raisedDescription() {
        #expect(MyronError.Reason.raised("boom").description == "Raised: boom")
    }

    // MARK: - Catching

    @Test("a raise in the body is passed to the handler", arguments: [
        ("(try (lambda (m) m) ((raise \"boom\")))", "\"boom\""),
        ("(try (lambda (m) (list \"caught\" m)) ((raise \"boom\")))", "(\"caught\" \"boom\")"),
        ("(try (lambda (m) 0) (1 (raise \"boom\") 3))", "0"),
        ("(define (f) (raise \"deep\")) (try (lambda (m) m) ((f)))", "\"deep\""),
        ("(define (h m) (list m)) (try h ((raise \"named\")))", "(\"named\")")
    ] as [ValueCase])
    func catches(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the message reaches the handler unaltered")
    func messageRoundTrips() {
        expectValue(
            "(try (lambda (m) (== m \"a (b) 'c' ; d\")) ((raise \"a (b) 'c' ; d\")))",
            "true")
        expectValue("(try (lambda (m) (length m)) ((raise \"\")))", "0")
    }

    @Test("a raise unwinds through nested procedure calls")
    func unwindsThroughRecursion() {
        let source = """
            (define (f n) (if (== n 0) (raise "bottom") (+ 1 (f (- n 1)))))
            (try (lambda (m) m) ((f 50)))
            """
        expectValue(source, "\"bottom\"")
    }

    @Test("the handler's result takes the place of the try form", arguments: [
        ("(+ 1 (try (lambda (m) 10) ((raise \"x\"))))", "11"),
        ("(list 1 (try (lambda (m) 2) ((list 3 (raise \"x\")))) 4)", "(1 2 4)"),
        ("(if (try (lambda (m) true) ((raise \"x\"))) \"yes\" \"no\")", "\"yes\"")
    ] as [ValueCase])
    func handlerResultInContext(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a raise inside a higher-order function is caught outside it", arguments: [
        ("(try (lambda (m) m) ((map (lambda (x) (if (== x 2) (raise \"two\") x)) '(1 2 3))))",
         "\"two\""),
        ("(try (lambda (m) m) ((filter (lambda (x) (raise \"f\")) '(1 2))))", "\"f\""),
        ("(try (lambda (m) m) ((reduce (lambda (a b) (raise \"r\")) 0 '(1 2))))", "\"r\""),
        ("(try (lambda (m) m) ((foldr (lambda (a b) (raise \"fr\")) 0 '(1 2))))", "\"fr\""),
        ("(try (lambda (m) m) ((all (lambda (x) (raise \"p\")) '(1 2))))", "\"p\""),
        ("(try (lambda (m) m) ((apply (lambda (x) (raise \"a\")) '(1))))", "\"a\"")
    ] as [ValueCase])
    func higherOrderUnwinding(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a try inside a higher-order function catches per element")
    func tryInsideMap() {
        expectValue(
            "(map (lambda (x) (try (lambda (m) 0) ((if (== x 2) (raise \"two\") x)))) '(1 2 3))",
            "(1 0 3)")
    }

    // MARK: - Normal Completion

    @Test("without a raise, try yields its last body", arguments: [
        ("(try (lambda (m) 0) (1))", "1"),
        ("(try (lambda (m) 0) (1 2 3))", "3"),
        ("(try (lambda (m) 0) ((define q 5) q))", "5"),
        ("(+ 1 (try (lambda (m) 0) ((+ 2 3))))", "6")
    ] as [ValueCase])
    func normalCompletion(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("an empty body yields nothing")
    func emptyBody() {
        expectValue("(try (lambda (m) 0) ())", "<nothing>")
    }

    @Test("the handler is not evaluated unless something raises", arguments: [
        ("(try junk (1 2))", "2"),
        ("(try \"not-a-function\" ((+ 1 2)))", "3"),
        ("(try (lambda (m) (/ 1 0)) (1))", "1")
    ] as [ValueCase])
    func handlerIsLazy(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a completed try no longer catches later raises")
    func handlerRetiresOnCompletion() {
        expectFailure(
            "(begin (try (lambda (m) \"caught\") (1)) (raise \"later\"))",
            reason: .raised("later"))
    }

    @Test("definitions made before a raise are kept")
    func definitionsSurviveRaise() {
        expectValue("(try (lambda (m) 0) ((define kept 7) (raise \"x\"))) kept", "7")
    }

    // MARK: - Nesting

    @Test("the innermost handler catches the raise")
    func innermostWins() {
        expectValue(
            "(try (lambda (m) \"outer\") ((try (lambda (m) \"inner\") ((raise \"x\")))))",
            "\"inner\"")
    }

    @Test("a raise from a handler goes to the enclosing try")
    func reraiseFromHandler() {
        expectValue(
            """
            (try (lambda (m) (list "outer" m))
                 ((try (lambda (m) (raise "again")) ((raise "first")))))
            """,
            "(\"outer\" \"again\")")
    }

    @Test("a handler does not catch its own raise")
    func handlerDoesNotCatchItself() {
        expectFailure("(try (lambda (m) (raise m)) ((raise \"x\")))", reason: .raised("x"))
    }

    @Test("a raise after an inner try completes goes to the outer handler")
    func outerCatchesAfterInnerCompletes() {
        expectValue(
            "(try (lambda (m) m) ((try (lambda (m) \"inner\") (1)) (raise \"after\")))",
            "\"after\"")
    }

    // MARK: - Environment

    @Test("the handler is evaluated in the environment of the try, not the raise")
    func handlerEnvironment() {
        let source = """
            (define h (lambda (m) (list "outer" m)))
            (define (g) (let ((h (lambda (m) "shadow"))) (raise "z")))
            (try h ((g)))
            """
        expectValue(source, "(\"outer\" \"z\")")
    }

    @Test("the handler closes over local bindings")
    func handlerClosesOverLocals() {
        expectValue(
            "(define (safe x) (try (lambda (m) (list x m)) ((raise \"bad\")))) (safe 4)",
            "(4 \"bad\")")
    }

    // MARK: - Uncaught Errors

    // Only `raise` is caught for now, built-in errors pass through a try.
    @Test("built-in errors are not caught", arguments: [
        ("(try (lambda (m) 0) ((/ 1 0)))", .divisionByZero),
        ("(try (lambda (m) 0) ((+ 1 \"x\")))", nil),
        ("(try (lambda (m) 0) (junk))", .unrecognisedSymbol)
    ] as [(String, MyronError.Reason?)])
    func builtInErrorsPassThrough(_ c: (String, MyronError.Reason?)) {
        expectFailure(c.0, reason: c.1)
    }

    @Test("a handler that is not a function fails when invoked")
    func nonFunctionHandler() {
        expectFailure(
            "(try \"fallback\" ((raise \"x\")))",
            reason: .expectedFunction(.string))
    }

    @Test("a handler with the wrong arity fails when invoked")
    func handlerArity() {
        expectArityFailure("(try (lambda () 0) ((raise \"x\")))")
        expectArityFailure("(try (lambda (a b) 0) ((raise \"x\")))")
    }

    @Test("an unbound handler fails when invoked")
    func unboundHandler() {
        expectFailure("(try junk ((raise \"x\")))", reason: .unrecognisedSymbol)
    }

    @Test("an error in the handler escapes the try")
    func handlerError() {
        expectFailure("(try (lambda (m) (/ 1 0)) ((raise \"x\")))", reason: .divisionByZero)
    }

    // MARK: - Form Validation

    @Test("try takes a handler and a list of bodies", arguments: [
        ("(try)", .unexpectedArity(0, .exactly(2))),
        ("(try (lambda (m) m))", .unexpectedArity(1, .exactly(2))),
        ("(try (lambda (m) m) (1) (2))", .unexpectedArity(3, .exactly(2))),
        ("(try (lambda (m) m) 1)", .unexpectedType(.integer, [.list]))
    ] as [FailureCase])
    func formErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: - Stack

    @Test("a caught raise leaves the stack as it was before the try")
    func caughtRaiseRestoresStack() {
        // Each iteration raises from inside a try, a leftover frame per catch
        // would exceed the limit long before the loop finishes.
        let source = """
            (define (f n)
              (if (== n 0) "done"
                  (begin (try (lambda (m) 0) ((raise "x"))) (f (- n 1)))))
            (f 10000)
            """
        guard case .success(let value) = Self.eval(source, limit: 200) else {
            Issue.record("(f 10000) failed under a limit of 200")
            return
        }
        #expect(value.description == "\"done\"")
    }

    @Test("a completed try leaves the stack as it was before the try")
    func completedTryRestoresStack() {
        let source = """
            (define (f n)
              (if (== n 0) "done"
                  (begin (try (lambda (m) 0) (1)) (f (- n 1)))))
            (f 10000)
            """
        guard case .success(let value) = Self.eval(source, limit: 200) else {
            Issue.record("(f 10000) failed under a limit of 200")
            return
        }
        #expect(value.description == "\"done\"")
    }

    @Test("a body inside try is not in tail position")
    func bodyIsNotTailCall() {
        // The handler frame stays beneath the body, so recursion through a
        // try costs depth even when the call is the last body.
        let source = """
            (define (f n) (if (== n 0) 0 (try (lambda (m) m) ((f (- n 1))))))
            (f 10000)
            """
        guard case .failure(let errors) = Self.eval(source, limit: 200) else {
            Issue.record("(f 10000) did not fail under a limit of 200")
            return
        }
        #expect(errors.contains { error in
            if case .exceededMaximumStackDepth = error.reason { return true }
            return false
        })
    }

    @Test("the session is usable after an uncaught raise")
    func sessionUsableAfterRaise() {
        let session = MyronSession()
        #expect(session.eval("(raise \"x\")").asFailure?.first?.reason == .raised("x"))
        #expect(session.eval("(try (lambda (m) m) ((+ 1 2)))").asSuccess?.description == "3")
    }

    // MARK: - Re-entrancy

    @Test("a raise inside a re-entrant evaluation is caught by the caller's try")
    func reentrantRaiseCaughtOutside() throws {
        let session = MyronSession()
        let box = SessionBox(session)
        try session.define("inner") { v in
            guard let result = try box.session?.eval(v.requireString()) else { return MyronValue.nothing }
            if let error = result.asFailure?.first { throw error }
            return result.asSuccess ?? .nothing
        }

        #expect(session.eval("(define (boom) (raise \"deep\"))").isSuccess)
        let source = "(list 1 (try (lambda (m) m) ((inner \"(boom)\"))) 3)"
        #expect(session.eval(source).asSuccess?.description == "(1 \"deep\" 3)")
    }

    @Test("a try inside a re-entrant evaluation catches without disturbing the caller")
    func reentrantTryCaughtInside() throws {
        let session = MyronSession()
        let box = SessionBox(session)
        try session.define("inner") { v in
            try #require(box.session?.eval(v.requireString()).asSuccess)
        }

        #expect(session.eval("(define (safe) (try (lambda (m) m) ((raise \"x\"))))").isSuccess)
        let source = "(list 1 (inner \"(safe)\") 3)"
        #expect(session.eval(source).asSuccess?.description == "(1 \"x\" 3)")
    }

}

// MARK: - Session Box

// Holds the session weakly so a primitive can re-enter it without a cycle.
private final class SessionBox: @unchecked Sendable {
    weak var session: MyronSession?
    init(_ session: MyronSession) { self.session = session }
}
