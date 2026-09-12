import Foundation

// MARK: - MyronError

public struct MyronError: Error, Sendable {

    public enum Reason: Sendable, Equatable {
        case cannotBeNegative
        case containingEnvironmentNoLongerExists
        case dictionaryValueCannotBeNothing
        case divisionByZero
        case duplicateKeys([Int])
        case emptyApplication
        case exceededMaximumStackDepth(Int)
        case expectedExpressionAfterTick
        case expectedFunction(MyronValue.Kind)
        case expectedQuote
        case expectedRightBracket
        case incomparableTypes
        case inequatableTypes
        case internalError(String)
        case invalidKey(MyronValue.Kind)
        case invalidNumber
        case malformedAlist(Int)
        case overflow
        case subscriptOutOfBounds(Int, Int)
        case unexpectedArity(Int, IntegerExpectation)
        case typeCastFailed(MyronValue.Kind, MyronValue.Kind)
        case unexpectedType(MyronValue.Kind?, Set<MyronValue.Kind>)
        case unimplementedFeature
        case unmatchedParenthesis
        case unrecognisedSymbol
    }

    public let reason: Reason
    public let location: MyronLocation?
    public let message: String?

    init(
        reason: Reason,
        location: MyronLocation?,
        message: String? = nil
    ) {
        self.reason = reason
        self.location = location
        self.message = message
    }

    init(_ reason: Reason, at location: MyronLocation?) {
        self.reason = reason
        self.location = location
        self.message = nil
    }

    init(_ reason: Reason) {
        self.reason = reason
        self.location = nil
        self.message = nil
    }

}

// MARK: - Integer Expectation

extension MyronError {

    public enum IntegerExpectation: Sendable, Equatable {
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
        case .cannotBeNegative: return "Cannot be negative"
        case .containingEnvironmentNoLongerExists: return "Containing environment no longer exists"
        case .dictionaryValueCannotBeNothing: return "Dictionary value cannot be nothing"
        case .divisionByZero: return "Division by zero"
        case .duplicateKeys(let idxs): return "Duplicate keys at indices: \(idxs)"
        case .emptyApplication: return "Empty application"
        case .exceededMaximumStackDepth(let depth): return "Exceeded maximum stack depth: \(depth)"
        case .expectedExpressionAfterTick: return "Expected expression after tick"
        case .expectedFunction(let kind): return "Expected function but got \(kind)"
        case .expectedQuote: return "Expected quote"
        case .expectedRightBracket: return "Expected right bracket"
        case .incomparableTypes: return "Incomparable types"
        case .inequatableTypes: return "Inequatable types"
        case .internalError(let message): return "Internal error: \(message)"
        case .invalidKey(let kind): return "Invalid key, got: \(kind)"
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
