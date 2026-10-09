import Testing
@testable import Myron

// MARK: - Myron Signature

@Suite("Myron Signature")

struct MyronSignatureTests {

    private typealias Term = MyronSignature.Term

    // MARK: Parsing

    @Test("a count subscript sets the term's bounds", arguments: [
        ("({string})", 1, 1),
        ("({string}[1])", 1, 1),
        ("({string}[2])", 2, 2),
        ("({string}[2...])", 2, nil),
        ("({string}[2...3])", 2, 3),
        ("({string}[...2])", 0, 2),
        ("({string}[0...2])", 0, 2),
        ("({string}[...])", 0, nil)
    ] as [(String, Int, Int?)])
    func countSubscripts(_ source: String, _ minimum: Int, _ maximum: Int?) throws {
        let term = try #require(try MyronSignature(source).terms.first)
        #expect(term.minimum == minimum)
        #expect(term.maximum == maximum)
        #expect(term.constraint == .subset([.string]))
        #expect(!term.isUniform)
    }

    @Test("constraints name kinds, or any")
    func constraints() throws {
        let signature = try MyronSignature("( {any} {integer double} {record-type} )")
        #expect(signature.terms.map { term in term.constraint } == [
            .any, .subset([.integer, .double]), .subset([.recordType])
        ])
    }

    @Test("primitive names every primitive kind")
    func primitiveNamesEveryPrimitiveKind() throws {
        let term = try #require(try MyronSignature("({primitive})").terms.first)
        #expect(term.constraint == .subset([.primitive, .higherOrder, .higherProbe]))
    }

    @Test("a star makes a term uniform")
    func starMakesUniform() throws {
        let signature = try MyronSignature("({integer double}*[2...])")
        let term = try #require(signature.terms.first)
        #expect(term.isUniform)
        #expect(term.minimum == 2)
        #expect(term.maximum == nil)
    }

    @Test("an empty signature takes no arguments")
    func emptySignature() throws {
        #expect(try MyronSignature("()").terms.isEmpty)
        #expect(try MyronSignature("()").matchesKinds([]) == .match([]))
    }

    @Test("malformed signatures are rejected", arguments: [
        "",
        "{string}",
        "({string}",
        "({string}) extra",
        "({})",
        "({strng})",
        "({any string})",
        "({string}[0])",
        "({string}[...0])",
        "({string}[3...2])",
        "({string}[])",
        "({string}[..2])",
        "({string}[2..<3])",
        "({string}[-1...])",
        "({string}*)",
        "({string}[...] {integer}[...])",
        "({string}[1...2] {integer}[2...])"
    ])
    func malformed(_ source: String) {
        #expect(throws: MyronError.self) { try MyronSignature(source) }
    }

    @Test("a malformed signature names itself and the problem")
    func malformedMessage() {
        let error = #expect(throws: MyronError.self) { try MyronSignature("({strng})") }
        #expect(error?.reason == .malformedSignature("({strng})", "unknown kind 'strng'"))
    }

    // MARK: Description

    @Test("descriptions are canonical and parse back to the same signature", arguments: [
        ("({string})", "({string})"),
        ("({string}[1])", "({string})"),
        ("( {string}[2] )", "({string}[2])"),
        ("({integer double}[2...])", "({double integer}[2...])"),
        ("({string}[0...2])", "({string}[...2])"),
        ("({string}[...])", "({string}[...])"),
        ("({integer} {any}*[...])", "({integer} {any}*[...])"),
        ("({integer double}*[2...3])", "({double integer}*[2...3])"),
        ("({string}*[2...])", "({string}[2...])"),
        ("({integer double}*[1])", "({double integer})"),
        ("({primitive})", "({primitive})")
    ])
    func descriptions(_ source: String, _ canonical: String) throws {
        let signature = try MyronSignature(source)
        #expect(signature.description == canonical)
        #expect(try MyronSignature(signature.description) == signature)
    }

    @Test("equivalent spellings make equal signatures", arguments: [
        ("({string})", "({string}[1])"),
        ("({string}[...2])", "({string}[0...2])"),
        ("({string}*[...])", "({string}[...])")
    ])
    func equivalentSpellings(_ lhs: String, _ rhs: String) throws {
        #expect(try MyronSignature(lhs) == MyronSignature(rhs))
    }

    @Test("different counts make different signatures")
    func differentCounts() throws {
        #expect(try MyronSignature("({string}[...])") !=
            MyronSignature("({string}[1...])"))
    }

    // MARK: Matching

    @Test("fixed terms need exactly their count")
    func fixedTerms() throws {
        let signature = try MyronSignature("({integer} {string}[2])")
        #expect(signature.matchesKinds([.integer, .string, .string]) == .match([
            .subset([.integer]), .subset([.string]), .subset([.string])
        ]))
        #expect(signature.matchesKinds([.integer, .string]) == .unmetArity(.exactly(3)))
        #expect(signature.matchesKinds([.integer, .integer, .string]) ==
            .unmetKind(position: 1, allowed: [.string]))
    }

    @Test("an open term takes what the fixed terms leave, wherever it sits")
    func openTerm() throws {
        let signature = try MyronSignature("({integer} {string}[1...2] {symbol})")
        #expect(signature.matchesKinds([.integer, .string, .symbol]).isMatch)
        #expect(signature.matchesKinds([.integer, .string, .string, .symbol]).isMatch)
        #expect(signature.matchesKinds([.integer, .symbol]) == .unmetArity(.atLeast(3)))
        #expect(signature.matchesKinds([.integer, .string, .string, .string, .symbol]) ==
            .unmetArity(.atMost(4)))
        #expect(signature.matchesKinds([.integer, .string, .integer, .symbol]) ==
            .unmetKind(position: 2, allowed: [.string]))
    }

    @Test("an open term may take nothing")
    func openTermTakesNothing() throws {
        let signature = try MyronSignature("({integer} {any}[...])")
        #expect(signature.matchesKinds([.integer]) == .match([.subset([.integer])]))
        #expect(signature.matchesKinds([.integer, .string, .list]).isMatch)
        #expect(signature.matchesKinds([]) == .unmetArity(.atLeast(1)))
    }

    @Test("a term without a star admits a mix of its kinds")
    func mixedKinds() throws {
        let signature = try MyronSignature("({integer double}[2...])")
        #expect(signature.matchesKinds([.integer, .double, .integer]).isMatch)
    }

    @Test("a uniform term needs all its arguments to share a kind")
    func uniformKinds() throws {
        let signature = try MyronSignature("({integer double}*[2...])")
        #expect(signature.matchesKinds([.integer, .integer, .integer]).isMatch)
        #expect(signature.matchesKinds([.double, .double]).isMatch)
        #expect(signature.matchesKinds([.integer, .double]) ==
            .unmetKind(position: 1, allowed: [.integer]))

        let anything = try MyronSignature("({string} {any}*[...])")
        #expect(anything.matchesKinds([.string, .list, .list]).isMatch)
        #expect(anything.matchesKinds([.string, .list, .set]) ==
            .unmetKind(position: 2, allowed: [.list]))
    }

    // MARK: Standard Library

    @Test("every standard library signature is well formed")
    func standardLibrarySignatures() throws {
        for module in StandardEnvironment.modules {
            for primitive in module.primitiveDefinitions {
                guard case .failure(let error) = primitive.signature else { continue }
                Issue.record("\(primitive.primitiveName): \(error.reason)")
            }
        }
    }

    // MARK: Terms

    @Test("terms built directly are validated")
    func directTerms() throws {
        #expect(throws: MyronError.self) { try Term(constraint: .subset([])) }
        #expect(throws: MyronError.self) { try Term(constraint: .any, minimum: -1) }
        #expect(throws: MyronError.self) { try Term(constraint: .any, maximum: 0) }
        #expect(throws: MyronError.self) { try Term(constraint: .any, minimum: 3, maximum: 2) }

        let open = try Term(constraint: .any, minimum: 0, maximum: nil)
        #expect(throws: MyronError.self) { try MyronSignature(terms: [open, open]) }
    }

}

// MARK: - Helpers

private extension MyronSignature.MatchResult {

    var isMatch: Bool {
        if case .match = self { return true }
        return false
    }

}
