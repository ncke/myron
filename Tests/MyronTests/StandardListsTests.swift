import Testing
@testable import Myron

// MARK: - Lists

@Suite("Standard Lists")
struct StandardListsTests {

    @Test("head", arguments: [
        ("(head (quote (1 2 3)))", "1"),
        ("(head (quote (9)))", "9"),
        ("(head (quote ()))", "<nothing>")
    ] as [ValueCase])
    func head(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("tail", arguments: [
        ("(tail (quote (1 2 3)))", "(2 3)"),
        ("(tail (quote (1)))", "()"),
        ("(tail (quote ()))", "()")
    ] as [ValueCase])
    func tail(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("last", arguments: [
        ("(last (quote (1 2 3)))", "3"),
        ("(last (quote (9)))", "9"),
        ("(last (quote ()))", "<nothing>")
    ] as [ValueCase])
    func last(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("take", arguments: [
        ("(take 2 (quote (1 2 3)))", "(1 2)"),
        ("(take 0 (quote (1 2 3)))", "()"),
        ("(take 5 (quote (1 2)))", "(1 2)")
    ] as [ValueCase])
    func take(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("drop", arguments: [
        ("(drop 1 (quote (1 2 3)))", "(2 3)"),
        ("(drop 0 (quote (1 2 3)))", "(1 2 3)"),
        ("(drop 5 (quote (1 2)))", "()")
    ] as [ValueCase])
    func drop(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("length", arguments: [
        ("(length (quote (1 2 3)))", "3"),
        ("(length (quote ()))", "0"),
        ("(length (quote (1)))", "1")
    ] as [ValueCase])
    func length(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("empty", arguments: [
        ("(empty (quote ()))", "true"),
        ("(empty (quote (1)))", "false"),
        ("(empty (quote (1 2 3)))", "false")
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
        ("(head (quote (1)) (quote (2)))", .unexpectedArity),
        ("(take -1 (quote (1 2)))", .cannotBeNegative),
        ("(drop -1 (quote (1 2)))", .cannotBeNegative),
        ("(take \"x\" (quote (1)))", .typeMismatch),
        ("(take 1 5)", .expectedList)
    ] as [FailureCase])
    func listErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
