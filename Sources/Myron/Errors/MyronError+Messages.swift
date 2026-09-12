import Foundation

// MARK: - Error Message Helper

extension MyronError {

    func withMessage(in expression: String) -> MyronError {
        let message = self.asErrorMessage(in: expression)
        return MyronError(reason: self.reason, location: self.location, message: message)
    }

    private func asErrorMessage(in expression: String) -> String {
        var message = "ERROR: " + self.reason.description

        guard let (errorText, errorLocation) = extractText(from: expression) else {
            return message
        }

        message += "\n\(errorText)"

        let spacer = String(repeating: " ", count: errorLocation.lowerBound)
        let highlight = String(repeating: "^", count: errorLocation.count)
        message += "\n\(spacer)\(highlight)"

        return message
    }

    private func extractText(from expression: String) -> (String, MyronLocation)? {
        guard
            let location = self.location,
            location.lowerBound >= 0,
            let errorStart = expression.index(
                expression.startIndex,
                offsetBy: location.lowerBound,
                limitedBy: expression.endIndex),
            let errorFinish = expression.index(
                expression.startIndex,
                offsetBy: location.upperBound,
                limitedBy: expression.endIndex)
        else {
            return nil
        }

        var extractStart = expression.startIndex
        var cursor = errorStart
        while cursor > expression.startIndex {
            cursor = expression.index(before: cursor)

            if expression[cursor].isNewline {
                extractStart = expression.index(after: cursor)
                break
            }
        }

        var extractFinish = expression.endIndex
        if errorFinish < expression.endIndex {
            extractFinish = expression[errorFinish...].firstIndex { ch in ch.isNewline }
            ?? expression.endIndex
        }

        let text = String(expression[extractStart..<extractFinish])
        let textStart = expression.distance(from: extractStart, to: errorStart)
        let textFinish = expression.distance(from: extractStart, to: errorFinish)

        return (text, textStart..<textFinish)
    }

}
