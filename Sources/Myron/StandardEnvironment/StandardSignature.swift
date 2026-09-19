import Foundation

// MARK: - Standard Signature

struct StandardSignature {
    
    static let oneAny: Term = (.exactly(1), .any)
    static let oneHashmap: Term = (.exactly(1), .subset(Set([ .hashmap ])))
    static let oneInteger: Term = (.exactly(1), .subset(Set([ .integer ])))
    static let oneList: Term = (.exactly(1), .subset(Set([ .list ])))
    static let oneString: Term = (.exactly(1), .subset(Set([ .string ])))
    
    typealias Term = (Multiple, Constraint)
    
    enum Constraint {
        case subset(Set<MyronValue.Kind>)
        case any
    }
    
    enum Multiple {
        case exactly(Int)
    }
    
    private let terms: [Term]
    private let requiredArity: Int?
    private let allowsVariadic: Bool

    init(_ terms: [Term], allowsVariadic: Bool = false) {
        self.terms = terms
        self.requiredArity = Self.computeRequiredArityIfPossible(terms)
        self.allowsVariadic = allowsVariadic
    }

}

// MARK: - Initialiser

extension StandardSignature {

    private static func computeRequiredArityIfPossible(_ terms: [Term]) -> Int? {
        var requiredArity = 0
        for (multiple, _) in terms {
            guard case .exactly(let count) = multiple else { return nil }
            requiredArity += count
        }

        return requiredArity
    }

}

// MARK: - Matching

extension StandardSignature {
    
    enum MatchResult {
        case match([Constraint])
        case unmetArity(MyronError.IntegerExpectation)
        case unmetKind(position: Int, allowed: Set<MyronValue.Kind>)
    }

    func matchesKinds(_ kinds: [MyronValue.Kind]) throws -> MatchResult {
        if let requiredArity {
            if allowsVariadic, kinds.count < requiredArity {
                return .unmetArity(.atLeast(requiredArity))
            }

            if !allowsVariadic, kinds.count != requiredArity {
                return .unmetArity(.exactly(requiredArity))
            }
        }

        var matchedConstraints = [Constraint]()
        var kindCursor = 0
        var trailing: Constraint?

        for (multiple, constraint) in terms {
            guard case .exactly(let exactNumber) = multiple, exactNumber > 0 else {
                let explain = "unsupported multiple in `matchesKinds`, got: \(multiple)"
                throw MyronError(.internalError(explain))
            }

            for _ in 0 ..< exactNumber {
                guard kindCursor < kinds.count else {
                    return .unmetArity(.atLeast(kindCursor + 1))
                }

                if let unmet = Self.unmetKind(constraint, kinds[kindCursor], at: kindCursor) {
                    return unmet
                }

                matchedConstraints.append(constraint)
                kindCursor += 1
            }

            trailing = constraint
        }

        if allowsVariadic, let trailing {
            while kindCursor < kinds.count {
                if let unmet = Self.unmetKind(trailing, kinds[kindCursor], at: kindCursor) {
                    return unmet
                }

                matchedConstraints.append(trailing)
                kindCursor += 1
            }
        }

        guard kindCursor == kinds.count else {
            return .unmetArity(.exactly(kindCursor))
        }

        return .match(matchedConstraints)
    }

    private static func unmetKind(
        _ constraint: Constraint,
        _ kind: MyronValue.Kind,
        at position: Int
    ) -> MatchResult? {
        guard case .subset(let kindSubset) = constraint else { return nil }
        guard !kindSubset.contains(kind) else { return nil }
        return .unmetKind(position: position, allowed: kindSubset)
    }

}

// MARK: - Specificity

extension StandardSignature {

    enum Specificity: Equatable {
        case moreSpecific
        case lessSpecific
        case equallySpecific
        case incomparable
    }

    static func compareSpecificity(
        _ lhs: [Constraint],
        to rhs: [Constraint]
    ) throws -> Specificity {
        guard lhs.count == rhs.count else {
            let explain = "bad parameters in `compareSpecificity`, got \(lhs) and \(rhs)"
            throw MyronError(.internalError(explain))
        }

        var narrowsSomewhere = false
        var widensSomewhere = false

        for (lhsConstraint, rhsConstraint) in zip(lhs, rhs) {
            switch lhsConstraint.specificity(comparedTo: rhsConstraint) {
            case .moreSpecific: narrowsSomewhere = true
            case .lessSpecific: widensSomewhere = true
            case .equallySpecific: break
            case .incomparable: return .incomparable
            }
        }

        switch (narrowsSomewhere, widensSomewhere) {
        case (true, false): return .moreSpecific
        case (false, true): return .lessSpecific
        case (false, false): return .equallySpecific
        case (true, true): return .incomparable
        }
    }

}

fileprivate extension StandardSignature.Constraint {

    func specificity(
        comparedTo other: StandardSignature.Constraint
    ) -> StandardSignature.Specificity {
        switch (self, other) {
        case (.any, .any): return .equallySpecific
        case (.any, .subset): return .lessSpecific
        case (.subset, .any): return .moreSpecific
        case (.subset(let s), .subset(let o)):
            if s == o { return .equallySpecific }
            if s.isStrictSubset(of: o) { return .moreSpecific }
            if o.isStrictSubset(of: s) { return .lessSpecific }
            return .incomparable
        }
    }

}

// MARK: - Described Forms

extension StandardSignature {
    
    func describeForms(representation: String) throws -> Set<String> {
        var forms = [representation]

        for (multiple, constraint) in terms {
            guard case .exactly(let multipleNumber) = multiple, multipleNumber > 0 else {
                let explain = "unsupported multiple in `describeForms`, got: \(multiple)"
                throw MyronError(.internalError(explain))
            }

            let kinds: [String]
            switch constraint {
            case .any: kinds = ["any"]
            case .subset(let subset): kinds = subset.map { kind in "\(kind)" }.sorted()
            }

            var nextForms = [String]()

            for kind in kinds {
                let reps = [String](repeating: kind, count: multipleNumber).joined(separator: " ")
                let addition = " " + reps
                nextForms.append(contentsOf: forms.map { form in form + addition })
            }

            forms = nextForms
        }

        // A variadic signature repeats its final term, so the surplus is marked instead.
        if allowsVariadic { forms = forms.map { form in form + " ..." } }

        return Set(forms)
    }

}
