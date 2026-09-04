import Foundation

// MARK: - MyronError

public struct MyronError: Error, Sendable {

    public enum Reason: Sendable, Equatable {
        case cannotBeNegative
        case divisionByZero
        case emptyApplication
        case expectedExpressionAfterTick
        case expectedFunction(String)
        case expectedList
        case expectedProcedure
        case expectedQuote
        case expectedRightBracket
        case expectedSymbol
        case incomparableTypes
        case inequatableTypes
        case internalError
        case invalidNumber
        case overflow
        case subscriptOutOfBounds(Int, Int)
        case typeMismatch
        case unexpectedArity
        case unexpectedType(Value.Kind?, Set<Value.Kind>)
        case unimplementedFeature
        case unmatchedParenthesis
        case unrecognisedSymbol
    }

    public let reason: Reason
    public let location: Range<Int>?
    public let message: String?

    init(
        reason: Reason,
        location: Range<Int>?,
        message: String? = nil
    ) {
        self.reason = reason
        self.location = location
        self.message = message
    }

    init(_ reason: Reason, at location: Range<Int>?) {
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

// MARK: - Reason Description

extension MyronError.Reason: CustomStringConvertible {

    public var description: String {
        switch self {
        case .cannotBeNegative: return "Cannot be negative"
        case .divisionByZero: return "Division by zero"
        case .emptyApplication: return "Empty application"
        case .expectedExpressionAfterTick: return "Expected expression after tick"
        case .expectedFunction(let typeName): return "Expected function but got \(typeName)"
        case .expectedList: return "Expected list"
        case .expectedProcedure: return "Expected procedure"
        case .expectedQuote: return "Expected quote"
        case .expectedRightBracket: return "Expected right bracket"
        case .expectedSymbol: return "Expected symbol"
        case .incomparableTypes: return "Incomparable types"
        case .inequatableTypes: return "Inequatable types"
        case .internalError: return "Internal error"
        case .invalidNumber: return "Invalid number"
        case .overflow: return "Overflow"
        case .subscriptOutOfBounds(let got, let length):
            return "Subscript out of bounds: got \(got) for list of length \(length)"
        case .typeMismatch: return "Type mismatch"
        case .unexpectedArity: return "Unexpected arity"
        case .unexpectedType(let got, let expected):
            let expectedString = expected
                .map(\Value.Kind.description)
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
