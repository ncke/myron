import Foundation

// MARK: - Hint Accumulation

extension MyronError {

    func withHint(_ hint: Hint) -> MyronError {
        var next = [hint]
        if let hints { next = hints + next }
        return MyronError(reason: reason, location: location, message: message, hints: next)
    }

    func withHint(_ hint: Hint, if predicate: @autoclosure () -> Bool) -> MyronError {
        guard predicate() else { return self }
        return self.withHint(hint)
    }

}

// MARK: - MyronError.Hint

extension MyronError {

    enum Hint: Sendable {
        case alistElementDidNotMeetRequirements
        case alistValueCannotBeNothing
        case comparisonBetweenDifferentKinds
        case comparisonMetIncomparableKind
        case conditionNotBoolean
        case instructionForInternalError
        case mixedDifferentNumericKinds
        case stackDepthAdvice
    }

}

// MARK: - Description

extension MyronError.Hint: CustomStringConvertible {

    var description: String {
        switch self {
        case .alistElementDidNotMeetRequirements:
            return "Every alist element must itself be a list with two elements"
        case .alistValueCannotBeNothing:
            return "The value of an alist element cannot be nothing"
        case .comparisonBetweenDifferentKinds:
            return "Values of different kinds cannot be compared"
        case .comparisonMetIncomparableKind:
            return "Use `comparable?` to determine if a value is comparable"
        case .conditionNotBoolean:
            return "The condition did not evaluate to a `boolean`"
        case .instructionForInternalError:
            return "Issues can be raised at 'https://github.com/ncke/myron'"
        case .mixedDifferentNumericKinds:
            return "Use `double` and `integer` to convert between numeric kinds"
        case .stackDepthAdvice:
            return "Check for unbounded recursion that is not in tail position"
        }
    }

}

// MARK: - Automatic Hinting

extension MyronError {

    static func addAutomaticHintsIfNecessary(for reason: Reason, to hints: [Hint]?) -> [Hint]? {
        guard let automatics = Hint.automaticHintsFor(reason: reason) else { return hints }
        guard let existing = hints else { return automatics }
        let addable = automatics.filter { automatic in !existing.contains(automatic) }
        return existing + addable
    }

}

extension MyronError.Hint {

    static func automaticHintsFor(reason: MyronError.Reason) -> [MyronError.Hint]? {
        switch reason {
        case .exceededMaximumStackDepth: return [.stackDepthAdvice]
        case .internal: return [.instructionForInternalError]
        default: return nil
        }
    }

}

// MARK: - Equatable & Hashable

extension MyronError.Hint: Equatable, Hashable {}

// MARK: - Catch For Hint

func hinting<T>(_ hint: MyronError.Hint, _ body: @autoclosure () throws -> T) throws -> T {
    do {
        return try body()
    } catch let error as MyronError {
        throw error.withHint(hint)
    }
}

func hinting<T>(_ hint: MyronError.Hint, _ body: () throws -> T) throws -> T {
    do {
        return try body()
    } catch let error as MyronError {
        throw error.withHint(hint)
    }
}
