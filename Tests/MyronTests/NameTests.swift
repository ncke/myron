import Testing
@testable import Myron

// MARK: - Name Tests

@Suite("Names")

// A trailing dot is reserved for the `...` of a variadic parameter, so no name
// may end in one, wherever it is bound.

struct NameTests {

    private static func firstError(_ source: String) throws -> MyronError {
        try #require(MyronSession().eval(source).asFailure?.first)
    }

    @Test("a name ending in a dot cannot be bound", arguments: [
        ("(define x. 1)", "x."),
        ("(define . 1)", "."),
        ("(define a.b. 1)", "a.b."),
        ("(define (f. a) a)", "f."),
        ("(define (f a.) a.)", "a."),
        ("(lambda (a.) a.)", "a."),
        ("(lambda (a b..) b..)", "b.."),
        ("(let ((a. 1)) a.)", "a."),
        ("(let ((a 1) (b. 2)) b.)", "b."),
        ("(module m. ())", "m."),
        ("(module m (x.) (define x 1))", "x."),
        ("(make-record-type 'p. '(x))", "p."),
        ("(make-record-type 'p '(x.))", "x.")
    ])
    func trailingDotRejected(source: String, name: String) throws {
        let error = try Self.firstError(source)
        #expect(error.reason == .invalidName(name))
        #expect(error.hints == [.nameCannotEndInDot(name)])
    }

    @Test("the trailing dot is rejected before the binding is made")
    func nothingIsBound() {
        let session = MyronSession()
        _ = session.eval("(define x. 1)")
        #expect(session.query("x.") == nil)
    }

    @Test("a host cannot define a primitive whose name ends in a dot", arguments: [
        "x.", ".", "a.b."
    ])
    func hostNameRejected(_ name: String) {
        let session = MyronSession()
        let error = #expect(throws: MyronError.self) {
            try session.define(name) { _ in 1 }
        }

        #expect(error?.reason == .invalidName(name))
        #expect(error?.hints == [.nameCannotEndInDot(name)])
        #expect(session.query(name) == nil)
    }

    @Test("a dot elsewhere in a name is still allowed", arguments: [
        ("(define a.b 1) a.b", "1"),
        ("(define (f.g x) x) (f.g 2)", "2"),
        ("((lambda (a.b) a.b) 3)", "3"),
        ("(let ((a.b 4)) a.b)", "4"),
        ("((lambda (xs...) xs) 5 6)", "(5 6)")
    ] as [ValueCase])
    func innerDotAllowed(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the hint reaches the rendered message")
    func hintInMessage() throws {
        let error = try Self.firstError("(define x. 1)")
        let hint = MyronError.Hint.nameCannotEndInDot("x.")

        #expect(error.message?.contains("HINT: \(hint)") == true)
    }

}
