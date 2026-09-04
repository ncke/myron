import Testing
@testable import Myron

// MARK: - Sequence

@Suite("Standard Sequence")

struct StandardSequenceTests {

    @Test("sequence errors", arguments: [
        ("(length 5)", .unexpectedType(.integer, [.list, .string])),
    ] as [FailureCase])
    func listErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
