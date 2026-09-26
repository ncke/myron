import Foundation

// MARK: - MyronError

public struct MyronError: Error, Sendable {

    public enum Reason: Sendable, Equatable, Hashable {
        case ambiguousResolution(String, String, [String])
        case cannotBeNegative
        case containingEnvironmentNoLongerExists
        case couldNotResolve(String, String, [String])
        case divisionByZero
        case duplicateField(String, String)
        case duplicateKeys([Int])
        case emptyApplication
        case exceededMaximumStackDepth(Int)
        case expectedExpressionAfterTick
        case expectedFunction(MyronValue.Kind)
        case expectedQuote
        case hostError(String)
        case incomparableTypes
        case `internal`(String)
        case invalidName(String)
        case invalidNumber
        case malformedAlist(Int)
        case overflow
        case subscriptOutOfBounds(Int, Int)
        case unexpectedArity(Int, IntegerExpectation)
        case typeCastFailed(MyronValue.Kind, MyronValue.Kind)
        case unexpectedField(String, String, [String])
        case unexpectedType(MyronValue.Kind?, Set<MyronValue.Kind>)
        case unimplementedFeature
        case unmatchedParenthesis
        case unrecognisedSymbol
    }

    public let reason: Reason
    public let location: MyronLocation?
    public let message: String?
    let hints: [Hint]?

    init(
        reason: Reason,
        location: MyronLocation?,
        message: String?,
        hints: [Hint]?
    ) {
        self.reason = reason
        self.location = location
        self.message = message
        let augmentedHints = Self.addAutomaticHintsIfNecessary(for: reason, to: hints)
        self.hints = augmentedHints
    }

    init(
        reason: Reason,
        location: MyronLocation?,
        message: String? = nil
    ) {
        self.init(reason: reason, location: location, message: message, hints: nil)
    }

    init(_ reason: Reason, at location: MyronLocation?) {
        self.init(reason: reason, location: location, message: nil, hints: nil)
    }

    init(_ reason: Reason) {
        self.init(reason: reason, location: nil, message: nil, hints: nil)
    }

}

// MARK: - Location

extension MyronError {

    func withLocation(_ relocation: MyronLocation?) -> MyronError {
        return MyronError(reason: reason, location: relocation, message: message, hints: hints)
    }

}

// MARK: - Equatable & Hashable

extension MyronError: Hashable {

    public static func ==(lhs: MyronError, rhs: MyronError) -> Bool {
        lhs.reason == rhs.reason && lhs.location == rhs.location && lhs.message == rhs.message
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.reason)
        hasher.combine(self.location)
        hasher.combine(self.message)
    }

}

// MARK: - Integer Expectation

extension MyronError {

    public enum IntegerExpectation: Sendable, Equatable, Hashable {
        case exactly(Int)
        case atLeast(Int)
        case atMost(Int)
        case unspecified
    }

}

extension MyronError.IntegerExpectation: CustomStringConvertible {

    public var description: String {
        switch self {
        case .exactly(let count): return "\(count)"
        case .atLeast(let count): return "at least \(count)"
        case .atMost(let count): return "at most \(count)"
        case .unspecified: return "unspecified"
        }
    }

}

// MARK: - Reason Description

extension MyronError.Reason: CustomStringConvertible {

    public var description: String {
        switch self {
        case .ambiguousResolution(let representation, let gotSignature, let candidates):
            let msg = "Ambiguous resolution for \(representation), got: \(gotSignature)"
            if candidates.isEmpty { return "\(msg)" }
            let listed = candidates.joined(separator: "\n")
            return "\(msg)\nCandidates:\n\(listed)"
        case .cannotBeNegative: return "Cannot be negative"
        case .containingEnvironmentNoLongerExists: return "Containing environment no longer exists"
        case .couldNotResolve(let representation, let gotSignature, let expectedSignatures):
            let msg = "Could not resolve signature for \(representation), got: \(gotSignature)"
            if expectedSignatures.isEmpty { return "\(msg)"}
            let dym = expectedSignatures.joined(separator: "\n")
            return "\(msg)\nDid you mean:\n\(dym)"
        case .divisionByZero: return "Division by zero"
        case .duplicateKeys(let idxs): return "Duplicate keys at indices: \(idxs)"
        case .duplicateField(let field, let name):
            return "Record-type \(name) cannot have duplicate fields, got: \(field)"
        case .emptyApplication: return "Empty application"
        case .exceededMaximumStackDepth(let depth): return "Exceeded maximum stack depth: \(depth)"
        case .expectedExpressionAfterTick: return "Expected expression after tick"
        case .expectedFunction(let kind): return "Expected function but got \(kind)"
        case .expectedQuote: return "Expected quote"
        case .hostError(let description): return "Host error: \(description)"
        case .incomparableTypes: return "Incomparable types"
        case .internal(let message): return "Internal error: \(message)"
        case .invalidName(let name): return "Invalid name: \(name)"
        case .invalidNumber: return "Invalid number"
        case .malformedAlist(let idx): return "Malformed alist at index: \(idx)"
        case .overflow: return "Overflow"
        case .subscriptOutOfBounds(let got, let length):
            return "Subscript out of bounds: got \(got) for length \(length)"
        case .unexpectedArity(let got, let expected):
            switch expected {
            case .exactly, .atLeast, .atMost:
                return "Unexpected arity: got \(got), expected \(expected)"
            case .unspecified:
                return "Unexpected arity: got \(got)"
            }
        case .typeCastFailed(let src, let dst):
            return "Type cast failed: \(src) -> \(dst)"
        case .unexpectedField(let got, let name, let fields):
            let has = "(\(fields.joined(separator: " ")))"
            return "Unexpected field name for record-type \(name), got: \(got), has: \(has)"
        case .unexpectedType(let got, let expected):
            let expectedString = expected
                .map(\MyronValue.Kind.description)
                .sorted()
                .joined(separator: ", ")
            switch (got, expectedString) {
            case (nil, ""): return "Unexpected type"
            case (.some(let g), ""): return "Unexpected type, got \(g)"
            case (nil, let e): return "Unexpected type, expected \(e)"
            case (.some(let g), let e): return "Unexpected type, got \(g), expected \(e)"
            }
        case .unimplementedFeature: return "Unimplemented feature"
        case .unmatchedParenthesis: return "Unmatched parenthesis"
        case .unrecognisedSymbol: return "Unrecognised symbol"
        }
    }

}

// MARK: - Host Error

public struct MyronHostError: Error, CustomStringConvertible {
    public let description: String
    public init(_ description: String) { self.description = description }
}
