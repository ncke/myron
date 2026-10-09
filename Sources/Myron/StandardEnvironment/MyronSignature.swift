import Foundation

// MARK: - MyronSignature

public struct MyronSignature {

    public struct Term: Equatable, Hashable, Sendable {

        public enum Constraint: Equatable, Hashable, Sendable {
            case subset(Set<MyronValue.Kind>)
            case any
        }

        public let constraint: Constraint
        public let minimum: Int
        public let maximum: Int?
        public let isUniform: Bool

        public init(
            constraint: Constraint,
            minimum: Int = 1,
            maximum: Int? = 1,
            isUniform: Bool = false
        ) throws {
            if case .subset(let kinds) = constraint, kinds.isEmpty {
                throw Self.malformed("a constraint needs at least one kind")
            }

            guard minimum >= 0 else { throw Self.malformed("a count cannot be negative") }

            if let maximum {
                guard maximum >= 1 else { throw Self.malformed("a count must allow an argument") }
                guard maximum >= minimum else {
                    throw Self.malformed("a count's lower bound exceeds its upper bound")
                }
            }

            self.constraint = constraint
            self.minimum = minimum
            self.maximum = maximum

            let canHoldSeveral = maximum.map { max in max > 1 } ?? true
            let hasSeveralKinds: Bool
            switch constraint {
            case .any: hasSeveralKinds = true
            case .subset(let kinds): hasSeveralKinds = kinds.count > 1
            }
            self.isUniform = isUniform && canHoldSeveral && hasSeveralKinds
        }

        public var isFixed: Bool { return minimum == maximum }

        private static func malformed(_ explain: String) -> MyronError {
            return MyronError(.malformedSignature("", explain))
        }

    }

    public let terms: [Term]

    public init(terms: [Term]) throws {
        guard terms.filter({ term in !term.isFixed }).count <= 1 else {
            let explain = "only one term may have a count that isn't fixed"
            throw MyronError(.malformedSignature("", explain))
        }

        self.terms = terms
    }

    /// The fewest and most arguments the signature admits, where a `nil` maximum is unbounded.
    public var arity: (minimum: Int, maximum: Int?) {
        let minimum = terms.reduce(0) { sum, term in sum + term.minimum }
        let maximum = terms.reduce(Optional(0)) { sum, term in
            guard let sum, let max = term.maximum else { return nil }
            return sum + max
        }

        return (minimum, maximum)
    }

}

// MARK: - Signature Strings

extension MyronSignature {

    // Constraint:
    //   {any} or {kind1 kind2 ...}, using Myron's kind names e.g. integer, boolean, etc.
    //
    // Term = Constraint with an optional count subscript:
    //   {string}           exactly one, the same as {string}[1]
    //   {string}[2]        exactly two
    //   {string}[2...]     two or more
    //   {string}[2...3]    two or three
    //   {string}[...2]     at most two, the same as {string}[0...2]
    //   {string}[...]      any number, including none
    //
    // Each kind argument independently satisfies the constraint, so {integer double}[2...]
    // allows a mix of integers and doubles. A star before the subscript makes the term uniform:
    // {integer double}*[2...] is two or more integers, or two or more doubles.
    //
    // Signature = terms in parentheses, of which at most one may have a count that isn't
    // fixed. For example, "({integer} {any}*[...])" is an integer followed by any number of
    // arguments that share a kind.

    public init(_ string: String) throws {
        var parser = SignatureParser(string)
        do {
            try self.init(terms: try parser.parseSignature())
        } catch let error as MyronError {
            guard case .malformedSignature(_, let explain) = error.reason else { throw error }
            throw MyronError(.malformedSignature(string, explain))
        }
    }

}


// MARK: - Matching

extension MyronSignature {

    enum MatchResult: Equatable {
        case match([Term.Constraint])
        case unmetArity(MyronError.IntegerExpectation)
        case unmetKind(position: Int, allowed: Set<MyronValue.Kind>)
    }

    func matchesKinds(_ kinds: [MyronValue.Kind]) -> MatchResult {
        let fixedTerms = terms.filter { term in term.isFixed }
        let fixedCount = fixedTerms.reduce(0) { sum, term in sum + term.minimum }

        // The single open term, if there is one, takes whatever the fixed terms leave over.
        var openCount = 0
        if let open = terms.first(where: { term in !term.isFixed }) {
            let fewest = fixedCount + open.minimum
            guard kinds.count >= fewest else { return .unmetArity(.atLeast(fewest)) }

            if let maximum = open.maximum, kinds.count > fixedCount + maximum {
                return .unmetArity(.atMost(fixedCount + maximum))
            }

            openCount = kinds.count - fixedCount
        } else if kinds.count != fixedCount {
            return .unmetArity(.exactly(fixedCount))
        }

        var matched = [Term.Constraint]()
        var position = 0

        for term in terms {
            let count = term.isFixed ? term.minimum : openCount
            let leadingKind = position < kinds.count ? kinds[position] : nil

            for _ in 0 ..< count {
                let kind = kinds[position]

                if case .subset(let allowed) = term.constraint, !allowed.contains(kind) {
                    return .unmetKind(position: position, allowed: allowed)
                }

                // A uniform term's leading argument settles the kind for the rest.
                if term.isUniform, let leadingKind, kind != leadingKind {
                    return .unmetKind(position: position, allowed: [leadingKind])
                }

                matched.append(term.constraint)
                position += 1
            }
        }

        return .match(matched)
    }

}

// MARK: - Description

extension MyronSignature: CustomStringConvertible {

    public var description: String {
        return "(" + terms.map { term in term.description }.joined(separator: " ") + ")"
    }

}

extension MyronSignature.Term: CustomStringConvertible {

    public var description: String {
        let names: [String]
        switch constraint {
        case .any: names = ["any"]
        case .subset(let kinds): names = Set(kinds.map { kind in kind.description }).sorted()
        }

        let braced = "{" + names.joined(separator: " ") + "}"
        let star = isUniform ? "*" : ""

        switch (minimum, maximum) {
        case (1, 1): return braced
        case (let min, let max?) where min == max: return "\(braced)\(star)[\(min)]"
        case (0, nil): return "\(braced)\(star)[...]"
        case (0, let max?): return "\(braced)\(star)[...\(max)]"
        case (let min, nil): return "\(braced)\(star)[\(min)...]"
        case (let min, let max?): return "\(braced)\(star)[\(min)...\(max)]"
        }
    }

}

// MARK: - Specificity

extension MyronSignature {

    enum Specificity: Equatable {
        case moreSpecific
        case lessSpecific
        case equallySpecific
        case incomparable
    }

    static func compareSpecificity(
        _ lhs: [Term.Constraint],
        to rhs: [Term.Constraint]
    ) throws -> Specificity {
        guard lhs.count == rhs.count else {
            let explain = "bad parameters in `compareSpecificity`, got \(lhs) and \(rhs)"
            throw MyronError(.internal(explain))
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

fileprivate extension MyronSignature.Term.Constraint {

    func specificity(
        comparedTo other: MyronSignature.Term.Constraint
    ) -> MyronSignature.Specificity {
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

extension MyronSignature {

    func describeForms(representation: String) -> Set<String> {
        var forms = [representation]

        for term in terms {
            let kinds: [String]
            switch term.constraint {
            case .any: kinds = ["any"]
            case .subset(let subset): kinds = Set(subset.map { kind in "\(kind)" }).sorted()
            }

            let surplus = term.isFixed ? "" : " ..."
            var nextForms = [String]()

            for kind in kinds {
                let reps = [String](repeating: " " + kind, count: term.minimum).joined()
                let addition = reps + surplus
                nextForms.append(contentsOf: forms.map { form in form + addition })
            }

            forms = nextForms
        }

        return Set(forms)
    }

}

// MARK: - Conformances

extension MyronSignature: Equatable, Hashable, Sendable {}
