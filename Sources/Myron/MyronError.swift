import Foundation

// MARK: - MyronError

public struct MyronError: Error {

    public enum Reason {
        case cannotBeNegative
        case divisionByZero
        case emptyApplication
        case expectedQuote
        case expectedRightBracket
        case expectedSymbol
        case incomparableTypes
        case inequatableTypes
        case internalError
        case invalidNumber
        case typeMismatch
        case unexpectedArity
        case unimplementedFeature
        case unmatchedParenthesis
        case unrecognisedSymbol
    }

    public let reason: Reason
    public let location: Range<String.Index>?
}

// MARK: - Reason Description

extension MyronError.Reason: CustomStringConvertible {

    public var description: String {
        switch self {
        case .cannotBeNegative: return "Cannot be negative"
        case .divisionByZero: return "Division by zero"
        case .emptyApplication: return "Empty application"
        case .expectedQuote: return "Expected quote"
        case .expectedRightBracket: return "Expected right bracket"
        case .expectedSymbol: return "Expected symbol"
        case .incomparableTypes: return "Incomparable types"
        case .inequatableTypes: return "Inequatable types"
        case .internalError: return "Internal error"
        case .invalidNumber: return "Invalid number"
        case .typeMismatch: return "Type mismatch"
        case .unexpectedArity: return "Unexpected arity"
        case .unimplementedFeature: return "Unimplemented feature"
        case .unmatchedParenthesis: return "Unmatched parenthesis"
        case .unrecognisedSymbol: return "Unrecognised symbol"
        }
    }

}
