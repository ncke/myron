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
        case bareVariadicEncountered
        case cannotUseReservedName(String)
        case comparisonBetweenDifferentKinds
        case comparisonMetIncomparableKind
        case conditionNotBoolean
        case evalDepthAdvice
        case instructionForInternalError
        case mixedDifferentNumericKinds
        case moduleCannotExportDottedName(String, String)
        case moduleDidNotDefineExports(String, [String])
        case moduleDoesNotExport(String, String)
        case moduleNamesCannotBeDotted(String)
        case nameCannotEndInDot(String)
        case nameWasWrittenWithEllipsis(String)
        case quotedSymbolNamesFunction(String)
        case splitSeparatorCannotBeEmptyString
        case stackDepthAdvice
        case tooManyVariadics
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
        case .bareVariadicEncountered:
            return "Bare variadics '...' are not allowed"
        case .cannotUseReservedName(let name):
            return "Reserved name '\(name)' cannot be used"
        case .comparisonBetweenDifferentKinds:
            return "Values of different kinds cannot be compared"
        case .comparisonMetIncomparableKind:
            return "Use `comparable?` to determine if a value is comparable"
        case .conditionNotBoolean:
            return "The condition did not evaluate to a `boolean`"
        case .evalDepthAdvice:
            return "Check for a host primitive whose evaluation calls itself again"
        case .instructionForInternalError:
            return "Issues can be raised at 'https://github.com/ncke/myron'"
        case .mixedDifferentNumericKinds:
            return "Use `double` and `integer` to convert between numeric kinds"
        case .moduleCannotExportDottedName(let name, let export):
            return "Module '\(name)' cannot have a dotted export: '\(export)'"
        case .moduleDidNotDefineExports(let name, let exports):
            let describeNames = exports.joined(separator: ", ")
            return "Module '\(name)' has missing exports: \(describeNames)"
        case .moduleDoesNotExport(let name, let export):
            return "Module '\(name)' does not export '\(export)'"
        case .moduleNamesCannotBeDotted(let name):
            return "Module '\(name)' cannot be dotted"
        case .nameCannotEndInDot(let name):
            return "Name '\(name)' cannot end in a dot"
        case .nameWasWrittenWithEllipsis(let name):
            return """
            Refer to '\(name)' without the '...', \
            or use `apply` to pass its elements as separate arguments
            """
        case .quotedSymbolNamesFunction(let name):
            return "Symbol '\(name)' names a function, consider removing quote"
        case .splitSeparatorCannotBeEmptyString:
            return "An empty string cannot be used as a split separator"
        case .stackDepthAdvice:
            return "Check for unbounded recursion that is not in tail position"
        case .tooManyVariadics:
            return "More than one variadic parameter is not allowed"
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
        case .exceededMaximumEvalDepth: return [.evalDepthAdvice]
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
