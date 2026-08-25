import Testing
@testable import Myron

// MARK: - Evaluation Helpers

typealias ValueCase = (source: String, expected: String)

typealias FailureCase = (source: String, reason: MyronError.Reason)

func expectValue(
    _ source: String,
    _ expected: String,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch MyronSession().eval(source) {

    case .success(let value):
        #expect(
            value.description == expected,
            "\(source) got  \(value) (expected \(expected))",
            sourceLocation: sourceLocation)

    case .failure(let errors):
        Issue.record(
            "\(source) got failure \(errors.map(\.reason)) (expected \(expected))",
            sourceLocation: sourceLocation)

    case .nothing:
        Issue.record(
            "\(source) got nothing (expected \(expected))",
            sourceLocation: sourceLocation)
    }
}

func expectFailure(
    _ source: String,
    reason: MyronError.Reason? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch MyronSession().eval(source) {

    case .failure(let errors):
        guard let reason else { return }
        #expect(
            errors.contains { $0.reason.description == reason.description },
            "\(source) got \(errors.map(\.reason)) (expected \(reason))",
            sourceLocation: sourceLocation)

    case .success(let value):
        Issue.record(
            "\(source) got \(value) (expected failure)",
            sourceLocation: sourceLocation)

    case .nothing:
        Issue.record(
            "\(source) got nothing (expected failure)",
            sourceLocation: sourceLocation)
    }
}
