import Testing
@testable import Myron

// MARK: - Lists

@Suite("Standard Lists")

struct StandardListsTests {

    @Test("head", arguments: [
        ("(head '(1 2 3))", "1"),
        ("(head '(9))", "9"),
        ("(head '())", "<nothing>")
    ] as [ValueCase])
    func head(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("tail", arguments: [
        ("(tail '(1 2 3))", "(2 3)"),
        ("(tail '(1))", "()"),
        ("(tail '())", "()")
    ] as [ValueCase])
    func tail(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("last", arguments: [
        ("(last '(1 2 3))", "3"),
        ("(last '(9))", "9"),
        ("(last '())", "<nothing>")
    ] as [ValueCase])
    func last(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("take", arguments: [
        ("(take 2 '(1 2 3))", "(1 2)"),
        ("(take 0 '(1 2 3))", "()"),
        ("(take 5 '(1 2))", "(1 2)")
    ] as [ValueCase])
    func take(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("drop", arguments: [
        ("(drop 1 '(1 2 3))", "(2 3)"),
        ("(drop 0 '(1 2 3))", "(1 2 3)"),
        ("(drop 5 '(1 2))", "()")
    ] as [ValueCase])
    func drop(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("length", arguments: [
        ("(length '(1 2 3))", "3"),
        ("(length '())", "0"),
        ("(length '(1))", "1")
    ] as [ValueCase])
    func length(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("empty?", arguments: [
        ("(empty? '())", "true"),
        ("(empty? '(1))", "false"),
        ("(empty? '(1 2 3))", "false")
    ] as [ValueCase])
    func empty(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("init", arguments: [
        ("(init '(1 2 3))", "(1 2)"),
        ("(init '(1))", "()"),
        ("(init '())", "()")
    ] as [ValueCase])
    func initial(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("cons", arguments: [
        ("(cons 1 '(2 3))", "(1 2 3)"),
        ("(cons 1 '())", "(1)"),
        ("(cons '(1) '(2))", "((1) 2)")
    ] as [ValueCase])
    func cons(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("list", arguments: [
        ("(list)", "()"),
        ("(list 1 2 3)", "(1 2 3)"),
        ("(list '(1) '(2))", "((1) (2))"),
        ("(list (+ 1 1) (* 2 2))", "(2 4)")
    ] as [ValueCase])
    func list(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("append", arguments: [
        ("(append '(1) '(2) '(3))", "(1 2 3)"),
        ("(append '(1 2))", "(1 2)"),
        ("(append '() '())", "()"),
        ("(append '(1 2) '())", "(1 2)")
    ] as [ValueCase])
    func append(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("reverse", arguments: [
        ("(reverse '(1 2 3))", "(3 2 1)"),
        ("(reverse '(1))", "(1)"),
        ("(reverse '())", "()")
    ] as [ValueCase])
    func reverse(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("nth", arguments: [
        ("(nth 0 '(1 2 3))", "1"),
        ("(nth 2 '(1 2 3))", "3")
    ] as [ValueCase])
    func nth(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("contains", arguments: [
        ("(contains 2 '(1 2 3))", "true"),
        ("(contains 9 '(1 2 3))", "false"),
        ("(contains 2 '())", "false"),
        ("(contains '(1) '((1) (2)))", "true")
    ] as [ValueCase])
    func contains(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("contains does not equate across types")
    func containsAcrossTypes() {
        expectValue("(contains \"a\" '(1 2))", "false")
        expectValue("(contains 1 '(1.0 2.0))", "false")
    }

    @Test("lists can be built by recursion")
    func recursiveConstruction() {
        expectValue(
            """
            (define (my-map f xs) (if (empty? xs) '() (cons (f (head xs)) (my-map f (tail xs)))))
            (my-map (lambda (x) (* x x)) '(1 2 3 4))
            """,
            "(1 4 9 16)")
    }

    @Test("list errors", arguments: [
        ("(head 5)", .unexpectedType(.integer, [.string, .list])),
        ("(tail 5)", .unexpectedType(.integer, [.string, .list])),
        ("(last 5)", .unexpectedType(.integer, [.string, .list])),
        ("(empty? 5)", .unexpectedType(.integer, [.string, .list])),
        ("(head '(1) '(2))", .unexpectedArity),
        ("(take -1 '(1 2))", .cannotBeNegative),
        ("(drop -1 '(1 2))", .cannotBeNegative),
        ("(take \"x\" '(1))", .typeMismatch),
        ("(take 1 5)", .unexpectedType(.integer, [.string, .list])),
        ("(init 5)", .unexpectedType(.integer, [.string, .list])),
        ("(reverse 5)", .unexpectedType(.integer, [.string, .list])),
        ("(cons 1 2)", .expectedList),
        ("(cons 1)", .unexpectedArity),
        ("(append 5)", .unexpectedType(.integer, [.string, .list])),
        ("(append)", .unexpectedArity),
        ("(nth 0 5)", .unexpectedType(.integer, [.string, .list])),
        ("(nth \"a\" '(1))", .typeMismatch),
        ("(nth 5 '(1 2))", .subscriptOutOfBounds(5, 2)),
        ("(nth -1 '(1 2))", .subscriptOutOfBounds(-1, 2)),
        ("(nth 0 '())", .subscriptOutOfBounds(0, 0)),
        ("(contains 1 5)", .unexpectedType(.integer, [.string, .list])),
        ("(contains 1)", .unexpectedArity)
    ] as [FailureCase])
    func listErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
