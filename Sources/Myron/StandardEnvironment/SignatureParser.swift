import Foundation

// MARK: - Signature Parser

struct SignatureParser {
    private let characters: [Character]
    private var cursor = 0

    init(_ string: String) {
        self.characters = Array(string)
    }

}

// MARK: - Parsing

extension SignatureParser {

    mutating func parseSignature() throws -> [MyronSignature.Term] {
        try expect("(")
        var terms = [MyronSignature.Term]()

        while peek() != ")" {
            terms.append(try parseTerm())
        }

        try expect(")")
        guard peek() == nil else { throw malformed("unexpected characters after the signature") }
        return terms
    }

    private mutating func parseTerm() throws -> MyronSignature.Term {
        let constraint = try parseConstraint()
        let isUniform = peek() == "*"
        if isUniform { cursor += 1 }

        guard peek() == "[" else {
            if isUniform { throw malformed("expected a subscript after '*'") }
            return try MyronSignature.Term(constraint: constraint)
        }

        let (minimum, maximum) = try parseCount()
        return try MyronSignature.Term(
            constraint: constraint,
            minimum: minimum,
            maximum: maximum,
            isUniform: isUniform)
    }

    private mutating func parseConstraint() throws -> MyronSignature.Term.Constraint {
        try expect("{")
        var names = [String]()

        while peek() != "}" {
            guard let name = parseName() else { throw malformed(expecting: "a kind name") }
            names.append(name)
        }

        try expect("}")

        if names.contains("any") {
            guard names.count == 1 else { throw malformed("'any' cannot be listed with kinds") }
            return .any
        }

        var kinds = Set<MyronValue.Kind>()
        for name in names {
            let named = MyronValue.Kind.allCases.filter { kind in kind.description == name }
            guard !named.isEmpty else { throw malformed("unknown kind '\(name)'") }
            kinds.formUnion(named)
        }

        guard !kinds.isEmpty else { throw malformed("a constraint needs at least one kind") }
        return .subset(kinds)
    }

    private mutating func parseCount() throws -> (minimum: Int, maximum: Int?) {
        try expect("[")
        let lower = try parseInteger()
        let isRange = try parseEllipsis()
        let upper = isRange ? try parseInteger() : lower

        try expect("]")

        guard isRange else {
            guard let lower else { throw malformed(expecting: "a count") }
            guard lower >= 1 else { throw malformed("a count must allow an argument") }
            return (lower, lower)
        }

        return (lower ?? 0, upper)
    }

}

// MARK: - Lexing

extension SignatureParser {

    private mutating func peek() -> Character? {
        while cursor < characters.count, characters[cursor].isWhitespace { cursor += 1 }
        return cursor < characters.count ? characters[cursor] : nil
    }

    private mutating func expect(_ character: Character) throws {
        guard peek() == character else { throw malformed(expecting: "'\(character)'") }
        cursor += 1
    }

    private mutating func parseEllipsis() throws -> Bool {
        guard peek() == "." else { return false }
        guard characters[cursor...].starts(with: "...") else {
            throw malformed(expecting: "'...'")
        }

        cursor += 3
        return true
    }

    private mutating func parseName() -> String? {
        _ = peek()
        let start = cursor
        while cursor < characters.count, characters[cursor].isLetter || characters[cursor] == "-" {
            cursor += 1
        }

        return cursor > start ? String(characters[start ..< cursor]) : nil
    }

    private mutating func parseInteger() throws -> Int? {
        _ = peek()
        let start = cursor
        while cursor < characters.count, characters[cursor].isASCII, characters[cursor].isNumber {
            cursor += 1
        }

        guard cursor > start else { return nil }
        guard let value = Int(String(characters[start ..< cursor])) else {
            throw malformed("a count is too large")
        }

        return value
    }

}

// MARK: - Parsing Errors

extension SignatureParser {

    private func malformed(expecting expected: String) -> MyronError {
        let got = cursor < characters.count ? "'\(characters[cursor])'" : "the end"
        return malformed("expected \(expected) but got \(got)")
    }

    private func malformed(_ explain: String) -> MyronError {
        return MyronError(.malformedSignature("", explain))
    }

}
