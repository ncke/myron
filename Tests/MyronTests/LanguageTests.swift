import Testing
@testable import Myron

// MARK: - Language Tests

@Suite("Language") struct LanguageTests {

    @Test("define binds a value")
    func defineValue() {
        expectValue("(define x 5) (+ x 1)", "6")
    }

    @Test("define binds a procedure")
    func defineProcedure() {
        expectValue("(define (square n) (* n n)) (square 4)", "16")
    }

    @Test("procedures close over their definition environment")
    func closure() {
        expectValue(
            "(define k 10) (define (addk n) (+ n k)) (addk 5)",
            "15")
    }

    @Test("if selects the true branch")
    func ifTrue() {
        expectValue("(if (gt 2 1) 10 20)", "10")
    }

    @Test("if selects the false branch")
    func ifFalse() {
        expectValue("(if (lt 2 1) 10 20)", "20")
    }

    @Test("language errors", arguments: [
        ("(if true 1)", .unexpectedArity),
        ("(if 1 10 20)", .typeMismatch),
        ("nonexistent", .unrecognisedSymbol),
        ("()", .emptyApplication)
    ] as [FailureCase])
    func languageErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
