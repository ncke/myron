import Testing
@testable import Myron

// MARK: - Error Hints

@Suite("Error Hints")

struct ErrorHintTests {

    private static let first = MyronError.Hint.comparisonBetweenDifferentKinds
    private static let second = MyronError.Hint.mixedDifferentNumericKinds

    // MARK: Accumulation

    @Test("an error starts with no hints")
    func noHintsByDefault() {
        #expect((MyronError(.cannotBeNegative).hints ?? []).isEmpty)
        #expect((MyronError(.cannotBeNegative, at: 0..<1).hints ?? []).isEmpty)
    }

    @Test("hints accumulate in the order they are added")
    func hintsAccumulateInOrder() {
        let error = MyronError(.cannotBeNegative)
            .withHint(Self.first)
            .withHint(Self.second)

        #expect(error.hints == [Self.first, Self.second])
    }

    @Test("adding a hint leaves the rest of the error alone")
    func hintPreservesError() {
        let error = MyronError(.cannotBeNegative, at: 3..<7).withHint(Self.first)

        #expect(error.reason == .cannotBeNegative)
        #expect(error.location == 3..<7)
        #expect(error.message == nil)
    }

    @Test("a conditional hint is added only when its condition holds")
    func conditionalHint() {
        let base = MyronError(.cannotBeNegative).withHint(Self.first)

        #expect(base.withHint(Self.second, if: true).hints == [Self.first, Self.second])
        #expect(base.withHint(Self.second, if: false).hints == [Self.first])
    }

    // MARK: Preservation

    @Test("relocating an error keeps its hints")
    func withLocationKeepsHints() {
        let error = MyronError(.cannotBeNegative)
            .withHint(Self.first)
            .withLocation(2..<4)

        #expect(error.location == 2..<4)
        #expect(error.hints == [Self.first])
    }

    @Test("attaching a message keeps the hints")
    func withMessageKeepsHints() {
        let error = MyronError(.cannotBeNegative, at: 0..<5)
            .withHint(Self.first)
            .withMessage(in: "(f 1)")

        #expect(error.message != nil)
        #expect(error.hints == [Self.first])
    }

    // MARK: Rendering

    @Test("a single hint follows the source caret")
    func singleHintRendering() throws {
        let error = MyronError(.cannotBeNegative, at: 0..<5)
            .withHint(Self.first)
            .withMessage(in: "(f 1)")
        let lines = try #require(error.message).split(separator: "\n").map(String.init)

        let caret = try #require(lines.firstIndex { line in line.contains("^") })
        let hint = try #require(lines.firstIndex(of: "HINT: \(Self.first)"))
        #expect(caret < hint)
        #expect(!lines.contains("HINTS:"))
    }

    @Test("several hints are listed under one heading, in order")
    func multipleHintRendering() throws {
        let error = MyronError(.cannotBeNegative, at: 0..<5)
            .withHint(Self.first)
            .withHint(Self.second)
            .withMessage(in: "(f 1)")
        let lines = try #require(error.message).split(separator: "\n").map(String.init)

        let heading = try #require(lines.firstIndex(of: "HINTS:"))
        #expect(Array(lines[(heading + 1)...]) == ["- \(Self.first)", "- \(Self.second)"])
        #expect(!lines.contains { line in line.hasPrefix("HINT: ") })
    }

    @Test("hints appear even when there is no source to point at")
    func hintsWithoutLocation() throws {
        let error = MyronError(.cannotBeNegative)
            .withHint(Self.first)
            .withMessage(in: "(f 1)")
        let message = try #require(error.message)

        #expect(!message.contains("^"))
        #expect(message.contains("HINT: \(Self.first)"))
    }

    @Test("an error without hints renders no hint block")
    func noHintBlock() throws {
        let error = MyronError(.cannotBeNegative, at: 0..<5).withMessage(in: "(f 1)")
        let message = try #require(error.message)

        #expect(!message.contains("HINT"))
    }

    // MARK: Automatic Hints

    @Test("some reasons carry a hint from the moment they are raised")
    func automaticHintOnCreation() {
        #expect(MyronError(.internal("broken")).hints?.count == 1)
        #expect(MyronError(.internal("broken"), at: 0..<1).hints?.count == 1)
    }

    @Test("an automatic hint comes first and is never repeated")
    func automaticHintNotRepeated() throws {
        let error = MyronError(.internal("broken"), at: 0..<5)
        let automatic = try #require(error.hints?.first)

        let copied = error
            .withHint(Self.first)
            .withLocation(1..<3)
            .withMessage(in: "(f 1)")

        #expect(copied.hints == [automatic, Self.first])
        let message = try #require(copied.message)
        #expect(message.components(separatedBy: automatic.description).count == 2)
    }

    @Test("an automatic hint reaches the message through a session")
    func automaticHintThroughSession() throws {
        let session = MyronSession(configuration: MyronSessionConfiguration(
            errorStyle: .verbose,
            maximumStackDepth: 50))
        let source = "(define (sum n) (if (== n 0) 0 (+ n (sum (- n 1))))) (sum 1000)"
        let error = try #require(session.eval(source).asFailure?.first)
        let automatic = try #require(error.hints?.first)

        #expect(error.hints?.count == 1)
        let message = try #require(error.message)
        #expect(message.components(separatedBy: automatic.description).count == 2)
    }

    // MARK: Hinting a Throwing Call

    private struct Unrelated: Error {}

    private static func fail() throws -> Int {
        throw MyronError(.cannotBeNegative)
    }

    private static func succeed() throws -> Int { 7 }

    @Test("hinting passes a value through when nothing throws")
    func hintingPassesValue() throws {
        #expect(try hinting(Self.first, Self.succeed()) == 7)
        #expect(try hinting(Self.first) { try Self.succeed() } == 7)
    }

    @Test("hinting adds its hint to a Myron error thrown inside it")
    func hintingAddsHint() {
        let fromExpression = #expect(throws: MyronError.self) {
            try hinting(Self.first, Self.fail())
        }
        let fromClosure = #expect(throws: MyronError.self) {
            try hinting(Self.first) { try Self.fail() }
        }

        #expect(fromExpression?.reason == .cannotBeNegative)
        #expect(fromExpression?.hints == [Self.first])
        #expect(fromClosure?.hints == [Self.first])
    }

    @Test("hinting lets other errors through untouched")
    func hintingIgnoresOtherErrors() {
        #expect(throws: Unrelated.self) {
            try hinting(Self.first) { () throws -> Int in throw Unrelated() }
        }
    }

    // MARK: Identity

    @Test("hints take no part in equality or hashing")
    func hintsIgnoredByEquality() {
        let plain = MyronError(.cannotBeNegative, at: 0..<1)
        let hinted = plain.withHint(Self.first).withHint(Self.second)

        #expect(plain == hinted)
        #expect(Set([plain, hinted]).count == 1)
    }

    // MARK: Through a Session

    @Test("a hinted error from a primitive body is positioned and keeps its hints")
    func hintsSurviveTheTrampoline() throws {
        let session = MyronSession()
        try session.define("hinted") { _ in
            throw MyronError(.cannotBeNegative).withHint(Self.first)
        }
        let error = try #require(session.eval("(hinted 1)").asFailure?.first)

        #expect(error.location != nil)
        #expect(error.hints == [Self.first])
        #expect(error.message?.contains("HINT: \(Self.first)") == true)
    }

    @Test("a primitive body's own location is not overwritten")
    func trampolineKeepsExistingLocation() throws {
        let session = MyronSession()
        try session.define("located") { _ in
            throw MyronError(.cannotBeNegative, at: 1..<3).withHint(Self.first)
        }
        let error = try #require(session.eval("(located 1)").asFailure?.first)

        #expect(error.location == 1..<3)
        #expect(error.hints == [Self.first])
    }

}
