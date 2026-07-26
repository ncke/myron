import Foundation

// MARK: - CompilerError

struct CompilerError: Error {

    enum Reason {
        case expectedQuote
        case expectedRightBracket
        case invalidNumber
        case unmatchedParenthesis
    }

    let reason: Reason
    let location: Range<String.Index>
}

// MARK: - Reason Description

extension CompilerError.Reason: CustomStringConvertible {

    var description: String {
        switch self {
        case .expectedQuote: return "Expected quote"
        case .expectedRightBracket: return "Expected right bracket"
        case .invalidNumber: return "Invalid number"
        case .unmatchedParenthesis: return "Unmatched parenthesis"
        }
    }

}
