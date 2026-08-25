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

    @Test("empty", arguments: [
        ("(empty '())", "true"),
        ("(empty '(1))", "false"),
        ("(empty '(1 2 3))", "false")
    ] as [ValueCase])
    func empty(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("list errors", arguments: [
        ("(head 5)", .expectedList),
        ("(tail 5)", .expectedList),
        ("(last 5)", .expectedList),
        ("(length 5)", .expectedList),
        ("(empty 5)", .expectedList),
        ("(head '(1) '(2))", .unexpectedArity),
        ("(take -1 '(1 2))", .cannotBeNegative),
        ("(drop -1 '(1 2))", .cannotBeNegative),
        ("(take \"x\" '(1))", .typeMismatch),
        ("(take 1 5)", .expectedList)
    ] as [FailureCase])
    func listErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
