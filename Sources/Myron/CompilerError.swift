import Foundation

// MARK: - CompilerError

struct CompilerError: Error {

    enum Reason {
        case expectedQuote
        case invalidNumber
    }

    let reason: Reason
    let location: Range<String.Index>
}

// MARK: - Reason Description

extension CompilerError.Reason: CustomStringConvertible {

    var description: String {
        switch self {
        case .expectedQuote: return "Expected quote"
        case .invalidNumber: return "Invalid number"
        }
    }

}
