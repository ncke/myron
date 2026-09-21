import Testing
import Myron // Imported without @testable to exercise only public API.

// MARK: - Host Error Types

// A host error that describes itself, and one that does not. The two together
// pin how a thrown error reaches `hostError`.

private struct PlainHostFailure: Error {}

private struct DescribedHostFailure: Error, CustomStringConvertible {
    var description: String { "described" }
}

// MARK: - Host Primitives

@Suite("Host Primitives")

struct HostPrimitiveTests {

    // MARK: Arity

    // The wrapper for each overload names its arguments positionally, so a body
    // that echoes them back catches a transposed or miscounted subscript.
    @Test("a body of every arity receives its arguments in order")
    func everyArityInOrder() throws {
        let session = MyronSession()
        try session.define("a0") { MyronValue.list([]) }
        try session.define("a1") { a in [a] }
        try session.define("a2") { a, b in [a, b] }
        try session.define("a3") { a, b, c in [a, b, c] }
        try session.define("a4") { a, b, c, d in [a, b, c, d] }
        try session.define("a5") { a, b, c, d, e in [a, b, c, d, e] }
        try session.define("a6") { a, b, c, d, e, f in [a, b, c, d, e, f] }

        #expect(session.eval("(a0)").asSuccess?.description == "()")
        #expect(session.eval("(a1 1)").asSuccess?.description == "(1)")
        #expect(session.eval("(a2 1 2)").asSuccess?.description == "(1 2)")
        #expect(session.eval("(a3 1 2 3)").asSuccess?.description == "(1 2 3)")
        #expect(session.eval("(a4 1 2 3 4)").asSuccess?.description == "(1 2 3 4)")
        #expect(session.eval("(a5 1 2 3 4 5)").asSuccess?.description == "(1 2 3 4 5)")
        #expect(session.eval("(a6 1 2 3 4 5 6)").asSuccess?.description == "(1 2 3 4 5 6)")
    }

    @Test("a nullary primitive is called with an empty application")
    func nullaryPrimitive() throws {
        let session = MyronSession()
        try session.define("answer") { 42 }

        #expect(session.eval("(answer)").asSuccess?.asInteger == 42)
        #expect(session.eval("(answer 1)").asFailure?.first?.reason
            == .unexpectedArity(1, .exactly(0)))
    }

    @Test("too few and too many arguments both report the expected arity")
    func arityMismatch() throws {
        let session = MyronSession()
        try session.define("two") { a, b in [a, b] }

        #expect(session.eval("(two 1)").asFailure?.first?.reason
            == .unexpectedArity(1, .exactly(2)))
        #expect(session.eval("(two 1 2 3)").asFailure?.first?.reason
            == .unexpectedArity(3, .exactly(2)))
    }

    // MARK: Reserved Names

    // A special form is intercepted before symbol lookup, so a primitive under
    // one of these names could never be reached in head position.
    @Test("a special form name cannot be defined", arguments: [
        "and", "begin", "cond", "define", "if", "lambda", "let", "or", "quote"
    ])
    func specialFormNamesRejected(_ name: String) {
        let session = MyronSession()
        let error = #expect(throws: MyronError.self) {
            try session.define(name) { _ in 1 }
        }

        #expect(error?.reason == .invalidName(name))
        #expect(session.query(name) == nil)
    }

    @Test("an ordinary name is accepted and reachable", arguments: [
        "plain", "with-dash", "question?", "bang!", "a.b", "+", "-", "<=", "x1"
    ])
    func ordinaryNamesAccepted(_ name: String) throws {
        let session = MyronSession()
        try session.define(name) { _ in 99 }

        #expect(session.query(name)?.kind == .primitive)
        #expect(session.eval("(\(name) 0)").asSuccess?.asInteger == 99)
    }

    // Symbols are not restricted to ASCII, so a host is no more restricted
    // than a Myron program is.
    @Test("a non-ascii name is accepted, as it is in source", arguments: [
        "café", "π", "naïve?", "日本語", "emoji-🦆"
    ])
    func nonAsciiNamesAccepted(_ name: String) throws {
        let session = MyronSession()
        try session.define(name) { _ in 99 }

        #expect(session.eval("(\(name) 0)").asSuccess?.asInteger == 99)

        // The same name defined in source reaches the same binding.
        #expect(session.eval("(define (call-it) (\(name) 0))").isSuccess)
        #expect(session.eval("(call-it)").asSuccess?.asInteger == 99)
    }

    // The name has to lex as the single symbol it claims to be, or the binding
    // could never be reached from source. Validation runs the lexer itself, so
    // every way of failing that is caught by one rule.
    @Test("a name that cannot be written as a symbol is rejected", arguments: [
        "with space", "with\ttab", "with\nnewline", "with\rreturn",
        "trailing ", " leading", "", "42", "1abc", "-7", "3.5", "true", "false",
        "semi;colon", "bracket(open", "bracket)close", "'ticked", "\"quoted\""
    ])
    func unwritableNamesRejected(_ name: String) {
        let session = MyronSession()
        let error = #expect(throws: MyronError.self) {
            try session.define(name) { _ in 1 }
        }

        #expect(error?.reason == .invalidName(name))
        #expect(session.query(name) == nil)
    }

    // The rule that matters is not a list of characters but an agreement: a
    // host may define exactly the names source can reach. Validation runs the
    // lexer, so tightening or loosening the lexer moves both sides together.
    @Test("a name is accepted exactly when source can reach it", arguments: [
        "plain", "with-dash", "question?", "+", "a.b", "café", "π",
        "with space", "", "42", "true", "semi;colon", "bracket)close", "'ticked",
        "null\u{0}char", "bell\u{7}char", "escape\u{1B}char"
    ])
    func acceptanceAgreesWithSource(_ name: String) {
        let session = MyronSession()

        var accepted = true
        do { try session.define(name) { _ in 99 } } catch { accepted = false }

        let reachable = session.eval("(\(name) 0)").asSuccess?.asInteger == 99

        #expect(accepted == reachable, "accepted \(accepted), reachable \(reachable)")
    }

    @Test("a rejected name leaves the environment untouched")
    func rejectedNameLeavesNothingBehind() {
        let session = MyronSession()
        let before = session.names
        #expect(throws: MyronError.self) { try session.define("if") { _ in 1 } }
        #expect(throws: MyronError.self) { try session.define("no good") { _ in 1 } }

        #expect(session.names == before)
    }

    // MARK: Errors From a Body

    @Test("a host error carries its own description")
    func hostErrorDescription() throws {
        let session = MyronSession()
        try session.define("fail") { _ in throw MyronHostError("deliberate") }

        #expect(session.eval("(fail 0)").asFailure?.first?.reason
            == .hostError("deliberate"))
    }

    // `localizedDescription` would render both of these as Foundation
    // boilerplate, discarding a description the error went to the trouble of
    // providing. `String(describing:)` is what keeps them distinct.
    @Test("an arbitrary error keeps its description rather than being localised")
    func describedErrorKeepsDescription() throws {
        let session = MyronSession()
        try session.define("fail") { _ in throw DescribedHostFailure() }

        #expect(session.eval("(fail 0)").asFailure?.first?.reason
            == .hostError("described"))
    }

    @Test("an undescribed error falls back to its type")
    func plainErrorFallsBackToType() throws {
        let session = MyronSession()
        try session.define("fail") { _ in throw PlainHostFailure() }

        #expect(session.eval("(fail 0)").asFailure?.first?.reason
            == .hostError("PlainHostFailure()"))
    }

    // The conversion helpers throw without a location, so the wrapper stamps
    // the call site on the way out. These two work as a pair: without the
    // stamping there is nothing for the verbose message to point at.
    @Test("an error thrown from a body is positioned at the call site")
    func bodyErrorIsPositioned() throws {
        let session = MyronSession()
        try session.define("needs-integer") { v in try v.requireInteger() }
        let error = try #require(session.eval("(needs-integer \"a\")").asFailure?.first)

        #expect(error.reason == .unexpectedType(.string, [.integer]))
        #expect(error.location != nil)
    }

    @Test("a positioned host error carries a source caret")
    func bodyErrorCarriesCaret() throws {
        let session = MyronSession()
        try session.define("boom") { _ in throw MyronHostError("deliberate") }
        let error = try #require(session.eval("(boom 1)").asFailure?.first)
        let message = try #require(error.message)

        #expect(message.contains("Host error: deliberate"))
        #expect(message.contains("(boom 1)"))
        #expect(message.contains("^"))
    }

    @Test("a terse session reports the reason without a message")
    func terseErrorStyle() throws {
        let configuration = MyronSessionConfiguration(
            errorStyle: .terse,
            maximumStackDepth: nil)
        let session = MyronSession(configuration: configuration)
        try session.define("boom") { _ in throw MyronHostError("deliberate") }
        let error = try #require(session.eval("(boom 1)").asFailure?.first)

        #expect(error.reason == .hostError("deliberate"))
        #expect(error.message == nil)
    }

    // MARK: Returning a Value

    @Test("a body returns any representable Swift type")
    func returningSwiftTypes() throws {
        let session = MyronSession()
        try session.define("r-integer") { _ in 7 }
        try session.define("r-double") { _ in 1.5 }
        try session.define("r-string") { _ in "s" }
        try session.define("r-boolean") { _ in true }
        try session.define("r-list") { _ in [1, 2] }
        try session.define("r-dictionary") { _ in ["a": 1] }
        try session.define("r-absent") { _ in Optional<Int>.none }
        try session.define("r-present") { _ in Optional<Int>.some(3) }

        #expect(session.eval("(r-integer 0)").asSuccess?.asInteger == 7)
        #expect(session.eval("(r-double 0)").asSuccess?.asDouble == 1.5)
        #expect(session.eval("(r-string 0)").asSuccess?.asString == "s")
        #expect(session.eval("(r-boolean 0)").asSuccess?.asBoolean == true)
        #expect(session.eval("(r-list 0)").asSuccess?.description == "(1 2)")
        #expect(session.eval("(r-dictionary 0)").asSuccess?.asHashmap?["a"]?.asInteger == 1)
        #expect(session.eval("(r-absent 0)").asSuccess?.kind == .nothing)
        #expect(session.eval("(r-present 0)").asSuccess?.asInteger == 3)
    }

    // The set and hashmap types convert inbound, so they have to go outbound
    // too or a body could take one and not give one back.
    @Test("a body returns the set and hashmap types in both flavours")
    func returningCollections() throws {
        let session = MyronSession()
        try session.define("r-swift-set") { _ in Set([1]) }
        try session.define("r-myron-set") { _ in [1, 2] as MyronSet }
        try session.define("r-myron-hashmap") { _ in MyronHashmap(["a": 1]) }
        try session.define("r-value") { _ in MyronValue.symbol("y") }

        #expect(session.eval("(r-swift-set 0)").asSuccess?.asSet?.count == 1)
        #expect(session.eval("(r-myron-set 0)").asSuccess?.asSet?.count == 2)
        #expect(session.eval("(r-myron-hashmap 0)").asSuccess?.asHashmap?["a"]?.asInteger == 1)
        #expect(session.eval("(r-value 0)").asSuccess?.asSymbol == "y")
    }

    // MARK: Shadowing and Redefinition

    @Test("a host primitive shadows a standard library name")
    func shadowsStandardLibrary() throws {
        let session = MyronSession()
        try session.define("not") { _ in "shadowed" }

        #expect(session.eval("(not true)").asSuccess?.asString == "shadowed")
    }

    @Test("defining the same name twice keeps the last definition")
    func redefinitionKeepsTheLast() throws {
        let session = MyronSession()
        try session.define("twice") { _ in 1 }
        try session.define("twice") { _ in 2 }

        #expect(session.eval("(twice 0)").asSuccess?.asInteger == 2)
    }

    @Test("Myron's own define replaces a host primitive")
    func myronDefineReplaces() throws {
        let session = MyronSession()
        try session.define("replaceable") { _ in 1 }
        #expect(session.eval("(define replaceable 99)").isSuccess)

        #expect(session.query("replaceable")?.asInteger == 99)
    }

    @Test("a host primitive is visible through the environment API")
    func visibleThroughTheEnvironment() throws {
        let session = MyronSession()
        try session.define("visible") { _ in 1 }

        #expect(session.query("visible")?.kind == .primitive)
        #expect(session.names.contains("visible"))

        // A host primitive is namespaced, so it describes itself under `host.`
        // rather than as the bare name it was defined under.
        #expect(session.eval("visible").asSuccess?.description
            == "<primitive: host.visible>")
    }

    // MARK: Identity

    // Host primitives carry an identity of their own, so sharing a name is not
    // enough to make two different functions equal.
    @Test("two host primitives with the same name are distinct values")
    func sameNameStaysDistinct() throws {
        let one = MyronSession()
        let other = MyronSession()
        try one.define("f") { _ in 1 }
        try other.define("f") { _ in 2 }

        let fromOne = try #require(one.query("f"))
        let fromOther = try #require(other.query("f"))

        #expect(fromOne != fromOther)
    }

    @Test("a host primitive is not equal to a standard one of the same name")
    func hostDiffersFromStandard() throws {
        let session = MyronSession()
        let standard = try #require(session.query("not"))
        try session.define("not") { _ in false }
        let hosted = try #require(session.query("not"))

        #expect(standard != hosted)

        // Each is namespaced, so the two are distinguishable on sight even
        // though they answer to the same name in source.
        #expect(standard.description == "<primitive: logic.not>")
        #expect(hosted.description == "<primitive: host.not>")
    }

    // The namespaced name says where a primitive came from, not which one it
    // is — identity is carried separately, much as two lambdas both describe
    // themselves as a procedure.
    @Test("two host primitives sharing a name describe themselves alike")
    func sameNameDescribesAlike() throws {
        let session = MyronSession()
        try session.define("f") { _ in 1 }
        let first = try #require(session.query("f"))
        try session.define("f") { _ in 2 }
        let second = try #require(session.query("f"))

        #expect(first.description == second.description)
        #expect(first != second)
    }

    @Test("standard primitives still compare by name across sessions")
    func standardPrimitivesCompareByName() {
        #expect(MyronSession().query("+") == MyronSession().query("+"))
        #expect(MyronSession().query("+") != MyronSession().query("-"))
    }

    @Test("a host primitive works as a key and a stored value")
    func hostPrimitiveAsKeyAndValue() throws {
        let session = MyronSession()
        try session.define("keyed") { _ in 1 }
        let primitive = try #require(session.query("keyed"))

        let hashmap = MyronHashmap([primitive: MyronValue.string("found")])
        #expect(hashmap[primitive]?.asString == "found")

        // Reached back out of a list, it is still callable.
        session.set("held", to: .list([primitive]))
        #expect(session.eval("((head held) 0)").asSuccess?.asInteger == 1)
    }

    // MARK: Working With the Language

    @Test("a host primitive works with the higher-order functions")
    func higherOrderFunctions() throws {
        let session = MyronSession()
        try session.define("double") { v in try v.requireInteger() * 2 }
        try session.define("big?") { v in try v.requireInteger() > 2 }
        try session.define("add") { a, b in try a.requireInteger() + b.requireInteger() }

        #expect(session.eval("(map double '(1 2 3))").asSuccess?.description == "(2 4 6)")
        #expect(session.eval("(filter big? '(1 2 3 4))").asSuccess?.description == "(3 4)")
        #expect(session.eval("(reduce add 0 '(1 2 3))").asSuccess?.asInteger == 6)
        #expect(session.eval("(all big? '(3 4))").asSuccess?.asBoolean == true)
        #expect(session.eval("(any big? '(1 2))").asSuccess?.asBoolean == false)
    }

    @Test("a host primitive is callable from a Myron procedure")
    func callableFromAProcedure() throws {
        let session = MyronSession()
        try session.define("double") { v in try v.requireInteger() * 2 }
        #expect(session.eval("(define (quadruple n) (double (double n)))").isSuccess)

        #expect(session.eval("(quadruple 3)").asSuccess?.asInteger == 12)
    }

    @Test("a host primitive is callable from a lambda passed back through map")
    func callableFromALambda() throws {
        let session = MyronSession()
        try session.define("triple") { v in try v.requireInteger() * 3 }

        let source = "(map (lambda (n) (+ (triple n) 1)) '(1 2))"
        #expect(session.eval(source).asSuccess?.description == "(4 7)")
    }

    @Test("a host primitive failing inside a procedure still reports a location")
    func failureInsideAProcedure() throws {
        let session = MyronSession()
        try session.define("needs-integer") { v in try v.requireInteger() }
        #expect(session.eval("(define (wrap x) (needs-integer x))").isSuccess)

        let error = try #require(session.eval("(wrap \"a\")").asFailure?.first)
        #expect(error.reason == .unexpectedType(.string, [.integer]))
        #expect(error.location != nil)
    }

    @Test("a host body sees the arguments already evaluated")
    func argumentsArriveEvaluated() throws {
        let session = MyronSession()
        try session.define("sum") { a, b in try a.requireInteger() + b.requireInteger() }

        #expect(session.eval("(sum (+ 1 1) (* 2 2))").asSuccess?.asInteger == 6)
    }

}
