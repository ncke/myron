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
            errors.map(\.reason).contains(reason),
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

func expectArityFailure(
    _ source: String,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch MyronSession().eval(source) {

    case .failure(let errors):
        let reasons = errors.map(\.reason)
        let isArity = reasons.contains {
            if case .unexpectedArity = $0 { return true }
            return false
        }
        #expect(
            isArity,
            "\(source) got \(reasons) (expected an arity error)",
            sourceLocation: sourceLocation)

    case .success(let value):
        Issue.record(
            "\(source) got \(value) (expected an arity error)",
            sourceLocation: sourceLocation)

    case .nothing:
        Issue.record(
            "\(source) got nothing (expected an arity error)",
            sourceLocation: sourceLocation)
    }
}
