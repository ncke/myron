import Foundation
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

// MARK: - Execution Context Helpers

// A context for calling a primitive directly, outside any machine. It belongs
// to a real process in a runtime of its own, which the context keeps alive.
func makeExecutionContext(at location: MyronLocation? = nil) -> MyronExecutionContext {
    let runtime = MyronRuntime()
    let process = runtime.makeProcess()
    let runtimeContext = MyronExecutionContext.RuntimeContext(process: process, runtime: runtime)
    return MyronExecutionContext(location: location, runtimeContext: runtimeContext)
}

// MARK: - Host Stack Helpers

// Some tests reach deep into the host thread's own stack: evaluations nested
// through host primitives, and the runtime's recursive teardown of a deeply
// nested value. How deep they can go depends on frame sizes, which change with
// the build and the code, and on a stack size no test host promises. An
// overflow is a crash rather than a failure, so these tests run on a thread
// with a stack of a known size, and report a wrong answer as a warning rather
// than a failure.

let knownStackSize = 16 << 20

func onKnownStack<T: Sendable>(_ body: @escaping @Sendable () -> T) -> T {
    let box = KnownStackResult<T>()
    let done = DispatchSemaphore(value: 0)
    let thread = Thread {
        box.value = body()
        done.signal()
    }
    thread.qualityOfService = .userInitiated
    thread.stackSize = knownStackSize
    thread.start()
    done.wait()
    return box.value!
}

func warnUnless(
    _ condition: Bool,
    _ comment: Comment,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    guard !condition else { return }
    Issue.record(comment, severity: .warning, sourceLocation: sourceLocation)
}

// Written once by the thread before it signals, and read once after the wait.
private final class KnownStackResult<T>: @unchecked Sendable {
    var value: T?
}
