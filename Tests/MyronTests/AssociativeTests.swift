import Testing
@testable import Myron

// MARK: - Associative

@Suite("Standard Associative")

struct StandardAssociativeTests {

    @Test("argument must be a list or hashmap", arguments: [
        ("(get 1 7)", .unexpectedType(.integer, [.list, .hashmap])),
        ("(keys \"a\")", .unexpectedType(.string, [.list, .hashmap])),
        ("(put 1 2 7)", .unexpectedType(.integer, [.list, .hashmap]))
    ] as [FailureCase])
    func notAList(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
