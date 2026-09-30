import Testing
@testable import Myron

// MARK: - Strings

@Suite("Standard Strings")

struct StandardStringsTests {

    // MARK: Sequence primitives over strings

    @Test("head", arguments: [
        ("(head \"abc\")", "\"a\""),
        ("(head \"a\")", "\"a\""),
        ("(head \"héllo\")", "\"h\""),
        ("(head \"\")", "<nothing>")
    ] as [ValueCase])
    func head(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("tail", arguments: [
        ("(tail \"abc\")", "\"bc\""),
        ("(tail \"a\")", "\"\""),
        ("(tail \"\")", "\"\"")
    ] as [ValueCase])
    func tail(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("init", arguments: [
        ("(init \"abc\")", "\"ab\""),
        ("(init \"a\")", "\"\""),
        ("(init \"\")", "\"\"")
    ] as [ValueCase])
    func initial(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("last", arguments: [
        ("(last \"abc\")", "\"c\""),
        ("(last \"a\")", "\"a\""),
        ("(last \"\")", "<nothing>")
    ] as [ValueCase])
    func last(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("take", arguments: [
        ("(take 2 \"abc\")", "\"ab\""),
        ("(take 0 \"abc\")", "\"\""),
        ("(take 5 \"ab\")", "\"ab\""),
        ("(take 2 \"héllo\")", "\"hé\""),
        ("(take 1 \"\")", "\"\"")
    ] as [ValueCase])
    func take(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("drop", arguments: [
        ("(drop 1 \"abc\")", "\"bc\""),
        ("(drop 0 \"abc\")", "\"abc\""),
        ("(drop 5 \"ab\")", "\"\""),
        ("(drop 2 \"héllo\")", "\"llo\"")
    ] as [ValueCase])
    func drop(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("take-last", arguments: [
        ("(take-last 2 \"abc\")", "\"bc\""),
        ("(take-last 0 \"abc\")", "\"\""),
        ("(take-last 5 \"ab\")", "\"ab\""),
        ("(take-last 4 \"héllo\")", "\"éllo\""),
        ("(take-last 1 \"\")", "\"\"")
    ] as [ValueCase])
    func takeLast(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("drop-last", arguments: [
        ("(drop-last 1 \"abc\")", "\"ab\""),
        ("(drop-last 0 \"abc\")", "\"abc\""),
        ("(drop-last 5 \"ab\")", "\"\""),
        ("(drop-last 3 \"héllo\")", "\"hé\"")
    ] as [ValueCase])
    func dropLast(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("range extracts characters up to the finish, excluding it", arguments: [
        ("(range 1 3 \"abcde\")", "\"bc\""),
        ("(range 0 5 \"abcde\")", "\"abcde\""),
        ("(range 1 99 \"abcde\")", "\"bcde\""),
        ("(range 2 2 \"abcde\")", "\"\""),
        ("(range 3 1 \"abcde\")", "\"\""),
        ("(range 5 7 \"abcde\")", "\"\""),
        ("(range 1 3 \"héllo\")", "\"él\""),
        ("(range 0 1 \"\")", "\"\"")
    ] as [ValueCase])
    func range(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("range-len extracts a length of characters from the start", arguments: [
        ("(range-len 1 2 \"abcde\")", "\"bc\""),
        ("(range-len 3 99 \"abcde\")", "\"de\""),
        ("(range-len 2 0 \"abcde\")", "\"\""),
        ("(range-len 5 2 \"abcde\")", "\"\""),
        ("(range-len 1 2 \"héllo\")", "\"él\""),
        ("(range-len 1 9223372036854775807 \"abc\")", "\"bc\""),
        ("(range-len 0 1 \"\")", "\"\"")
    ] as [ValueCase])
    func rangeLen(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("length counts characters, not bytes", arguments: [
        ("(length \"abc\")", "3"),
        ("(length \"\")", "0"),
        ("(length \"héllo\")", "5"),
        ("(length \"🇬🇧\")", "1")
    ] as [ValueCase])
    func length(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("empty?", arguments: [
        ("(empty? \"\")", "true"),
        ("(empty? \"a\")", "false"),
        ("(empty? \" \")", "false")
    ] as [ValueCase])
    func empty(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("append", arguments: [
        ("(append \"a\" \"b\" \"c\")", "\"abc\""),
        ("(append \"ab\")", "\"ab\""),
        ("(append \"\" \"\")", "\"\""),
        ("(append \"ab\" \"\")", "\"ab\"")
    ] as [ValueCase])
    func append(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("reverse", arguments: [
        ("(reverse \"abc\")", "\"cba\""),
        ("(reverse \"a\")", "\"a\""),
        ("(reverse \"\")", "\"\""),
        ("(reverse \"héllo\")", "\"olléh\"")
    ] as [ValueCase])
    func reverse(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("nth", arguments: [
        ("(nth 0 \"abc\")", "\"a\""),
        ("(nth 2 \"abc\")", "\"c\""),
        ("(nth 1 \"héllo\")", "\"é\"")
    ] as [ValueCase])
    func nth(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("contains is a substring search", arguments: [
        ("(contains? \"ll\" \"hello\")", "true"),
        ("(contains? \"hello\" \"hello\")", "true"),
        ("(contains? \"x\" \"hello\")", "false"),
        ("(contains? \"lo\" \"hel\")", "false"),
        ("(contains? \"\" \"hello\")", "true"),
        ("(contains? \"\" \"\")", "true"),
        ("(contains? \"a\" \"\")", "false"),
        ("(contains? \"LL\" \"hello\")", "false")
    ] as [ValueCase])
    func contains(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("contains on a string differs from contains on its characters")
    func containsSubstringVersusElement() {
        expectValue("(contains? \"ab\" \"abc\")", "true")
        expectValue("(contains? \"ab\" (explode \"abc\"))", "false")
    }

    @Test("sequence errors over strings", arguments: [
        ("(take -1 \"ab\")", .cannotBeNegative),
        ("(drop -1 \"ab\")", .cannotBeNegative),
        ("(take \"x\" \"ab\")", .unexpectedType(.string, [.integer])),
        ("(drop \"x\" \"ab\")", .unexpectedType(.string, [.integer])),
        ("(take-last -1 \"ab\")", .cannotBeNegative),
        ("(drop-last -1 \"ab\")", .cannotBeNegative),
        ("(take-last \"x\" \"ab\")", .unexpectedType(.string, [.integer])),
        ("(drop-last \"x\" \"ab\")", .unexpectedType(.string, [.integer])),
        ("(range -1 2 \"ab\")", .cannotBeNegative),
        ("(range 0 -1 \"ab\")", .cannotBeNegative),
        ("(range \"x\" 1 \"ab\")", .unexpectedType(.string, [.integer])),
        ("(range-len -1 2 \"ab\")", .cannotBeNegative),
        ("(range-len 0 -1 \"ab\")", .cannotBeNegative),
        ("(range-len 0 \"x\" \"ab\")", .unexpectedType(.string, [.integer])),
        ("(nth \"a\" \"abc\")", .unexpectedType(.string, [.integer])),
        ("(nth 3 \"abc\")", .subscriptOutOfBounds(3, 3)),
        ("(nth -1 \"abc\")", .subscriptOutOfBounds(-1, 3)),
        ("(nth 0 \"\")", .subscriptOutOfBounds(0, 0)),
        ("(contains? 1 \"abc\")", .unexpectedType(.integer, [.string])),
        ("(append \"a\" 1)", .unexpectedType(.integer, [.string]))
    ] as [FailureCase])
    func sequenceErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // MARK: Native string primitives

    @Test("explode splits a string into single-character strings", arguments: [
        ("(explode \"abc\")", "(\"a\" \"b\" \"c\")"),
        ("(explode \"a\")", "(\"a\")"),
        ("(explode \"\")", "()"),
        ("(explode \"héllo\")", "(\"h\" \"é\" \"l\" \"l\" \"o\")")
    ] as [ValueCase])
    func explode(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("implode joins a list of strings", arguments: [
        ("(implode '(\"a\" \"b\" \"c\"))", "\"abc\""),
        ("(implode \", \" '(\"a\" \"b\" \"c\"))", "\"a, b, c\""),
        ("(implode \"-\" '(\"a\"))", "\"a\""),
        ("(implode '())", "\"\""),
        ("(implode \", \" '())", "\"\""),
        ("(implode \"\" '(\"a\" \"b\"))", "\"ab\"")
    ] as [ValueCase])
    func implode(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("implode renders non-string elements as they print", arguments: [
        ("(implode '(1 2 3))", "\"123\""),
        ("(implode \" \" '(1 2.5 true))", "\"1 2.5 true\""),
        ("(implode \" \" '(a b))", "\"a b\""),
        ("(implode \"\" '((1 2)))", "\"(1 2)\"")
    ] as [ValueCase])
    func implodeNonStrings(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("explode and implode round-trip")
    func explodeImplodeRoundTrip() {
        expectValue("(implode (explode \"héllo\"))", "\"héllo\"")
        expectValue("(implode (map uppercase (explode \"abc\")))", "\"ABC\"")
        expectValue("(implode (reverse (explode \"abc\")))", "\"cba\"")
    }

    @Test("string renders any value as a string", arguments: [
        ("(string \"abc\")", "\"abc\""),
        ("(string \"\")", "\"\""),
        ("(string 42)", "\"42\""),
        ("(string -1)", "\"-1\""),
        ("(string 1.5)", "\"1.5\""),
        ("(string true)", "\"true\""),
        ("(string 'sym)", "\"sym\""),
        ("(string '(1 2))", "\"(1 2)\""),
        ("(string '())", "\"()\"")
    ] as [ValueCase])
    func string(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("string of a string is the identity, not a quotation")
    func stringIdentity() {
        expectValue("(length (string \"abc\"))", "3")
        expectValue("(eq (string \"abc\") \"abc\")", "true")
    }

    @Test("string renders strings inside lists quoted")
    func stringOfListQuotesStrings() {
        expectValue("(string '(1 \"a\"))", "\"(1 \"a\")\"")
    }

    @Test("lowercase and uppercase", arguments: [
        ("(lowercase \"ABC\")", "\"abc\""),
        ("(lowercase \"aBc\")", "\"abc\""),
        ("(lowercase \"\")", "\"\""),
        ("(lowercase \"ÀB\")", "\"àb\""),
        ("(uppercase \"abc\")", "\"ABC\""),
        ("(uppercase \"aBc\")", "\"ABC\""),
        ("(uppercase \"\")", "\"\""),
        ("(uppercase \"àb\")", "\"ÀB\""),
        ("(uppercase \"123\")", "\"123\"")
    ] as [ValueCase])
    func caseConversion(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("trim removes surrounding whitespace only", arguments: [
        ("(trim \"  a b  \")", "\"a b\""),
        ("(trim \"abc\")", "\"abc\""),
        ("(trim \"   \")", "\"\""),
        ("(trim \"\")", "\"\""),
        ("(trim \"\ta\n\")", "\"a\"")
    ] as [ValueCase])
    func trim(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("lines splits on newlines and keeps empty lines", arguments: [
        ("(lines \"a\nb\nc\")", "(\"a\" \"b\" \"c\")"),
        ("(lines \"a\")", "(\"a\")"),
        ("(lines \"a\n\nb\")", "(\"a\" \"\" \"b\")"),
        ("(lines \"a\n\")", "(\"a\" \"\")"),
        ("(lines \"\n\")", "(\"\" \"\")"),
        ("(lines \"\")", "(\"\")"),
        ("(lines \"a b\nc d\")", "(\"a b\" \"c d\")"),
        ("(lines \"a\r\nb\")", "(\"a\" \"b\")"),
        ("(lines \"a\rb\")", "(\"a\" \"b\")")
    ] as [ValueCase])
    func lines(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("words splits on any whitespace and drops empties", arguments: [
        ("(words \"a b c\")", "(\"a\" \"b\" \"c\")"),
        ("(words \"a  b   c\")", "(\"a\" \"b\" \"c\")"),
        ("(words \"  a b  \")", "(\"a\" \"b\")"),
        ("(words \"a\")", "(\"a\")"),
        ("(words \"\")", "()"),
        ("(words \"   \")", "()"),
        ("(words \"a\tb\nc\")", "(\"a\" \"b\" \"c\")"),
        ("(words \"héllo wörld\")", "(\"héllo\" \"wörld\")")
    ] as [ValueCase])
    func words(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("lines and words compose with the list primitives")
    func linesAndWordsCompose() {
        expectValue("(map length (words \"hello big world\"))", "(5 3 5)")
        expectValue("(implode \" \" (words \"  a   b \"))", "\"a b\"")
        expectValue("(length (lines \"one\ntwo\nthree\"))", "3")
        expectValue("(map words (lines \"a b\nc\"))", "((\"a\" \"b\") (\"c\"))")
        expectValue(
            "(implode \"\n\" (map uppercase (lines \"ab\ncd\")))",
            "\"AB\nCD\"")
    }

    @Test("split-all splits on every separator and keeps empty fields", arguments: [
        ("(split-all \",\" \"a,b,c\")", "(\"a\" \"b\" \"c\")"),
        ("(split-all \", \" \"a, b, c\")", "(\"a\" \"b\" \"c\")"),
        ("(split-all \",\" \"a,,b\")", "(\"a\" \"\" \"b\")"),
        ("(split-all \",\" \",a,\")", "(\"\" \"a\" \"\")"),
        ("(split-all \",\" \",\")", "(\"\" \"\")"),
        ("(split-all \",\" \"abc\")", "(\"abc\")"),
        ("(split-all \",\" \"\")", "(\"\")"),
        ("(split-all \"aa\" \"aaab\")", "(\"\" \"ab\")"),
        ("(split-all \"ab\" \"aab\")", "(\"a\" \"\")"),
        ("(split-all \"👍\" \"a👍b👍\")", "(\"a\" \"b\" \"\")"),
        ("(split-all \"-\" \"hé-llo\")", "(\"hé\" \"llo\")")
    ] as [ValueCase])
    func splitAll(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("implode with the same separator undoes split-all", arguments: [
        "a,b,c", "a,,b", ",a,", ",", "", "abc"
    ])
    func splitAllImplodeRoundTrip(_ str: String) {
        expectValue("(implode \",\" (split-all \",\" \"\(str)\"))", "\"\(str)\"")
    }

    @Test("split-once splits on the first separator into two parts", arguments: [
        ("(split-once \"=\" \"key=value\")", "(\"key\" \"value\")"),
        ("(split-once \"=\" \"a=b=c\")", "(\"a\" \"b=c\")"),
        ("(split-once \"::\" \"a::b\")", "(\"a\" \"b\")"),
        ("(split-once \"=\" \"key=\")", "(\"key\" \"\")"),
        ("(split-once \"=\" \"=value\")", "(\"\" \"value\")"),
        ("(split-once \"=\" \"=\")", "(\"\" \"\")"),
        ("(split-once \"👍\" \"a👍b\")", "(\"a\" \"b\")")
    ] as [ValueCase])
    func splitOnce(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("split-once gives the whole string alone when the separator is absent", arguments: [
        ("(split-once \"=\" \"key\")", "(\"key\")"),
        ("(split-once \"=\" \"\")", "(\"\")"),
        ("(split-once \"abc\" \"ab\")", "(\"ab\")")
    ] as [ValueCase])
    func splitOnceAbsent(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("the length of split-once tells whether the separator was found")
    func splitOnceDistinguishesAbsence() {
        expectValue("(length (split-once \"=\" \"key=\"))", "2")
        expectValue("(length (split-once \"=\" \"key\"))", "1")
    }

    @Test("find-first gives the character position of the first match", arguments: [
        ("(find-first \"a\" \"abc\")", "0"),
        ("(find-first \"b\" \"abc\")", "1"),
        ("(find-first \"c\" \"abc\")", "2"),
        ("(find-first \"bc\" \"abcbc\")", "1"),
        ("(find-first \"abc\" \"abc\")", "0"),
        ("(find-first \"aab\" \"aaab\")", "1"),
        ("(find-first \"b\" \"a👍b\")", "2"),
        ("(find-first \"b\" \"🇬🇧b\")", "1"),
        ("(find-first \"l\" \"héllo\")", "2")
    ] as [ValueCase])
    func findFirst(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("find-first finds the empty string at the start, as contains? does", arguments: [
        ("(find-first \"\" \"abc\")", "0"),
        ("(find-first \"\" \"\")", "0"),
        ("(contains? \"\" \"\")", "true")
    ] as [ValueCase])
    func findFirstEmpty(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("find-first gives nothing when there is no match", arguments: [
        ("(find-first \"z\" \"abc\")", "<nothing>"),
        ("(find-first \"abcd\" \"abc\")", "<nothing>"),
        ("(find-first \"cd\" \"abc\")", "<nothing>"),
        ("(find-first \"a\" \"\")", "<nothing>")
    ] as [ValueCase])
    func findFirstAbsent(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a find-first position works with nth and range")
    func findFirstComposes() {
        expectValue("(nth (find-first \"b\" \"a👍b\") \"a👍b\")", "\"b\"")
        expectValue("(range 0 (find-first \"=\" \"k👍=v\") \"k👍=v\")", "\"k👍\"")
    }

    @Test("an empty separator is refused with a hint", arguments: [
        "(split-all \"\" \"abc\")",
        "(split-once \"\" \"abc\")"
    ])
    func emptySeparatorHint(_ source: String) {
        guard case .failure(let errors) = MyronSession().eval(source) else {
            Issue.record("\(source) did not fail")
            return
        }

        #expect(errors.map(\.reason) == [.cannotBeEmpty])
        #expect(errors.first?.hints == [.splitSeparatorCannotBeEmptyString])
    }

    @Test("native string errors", arguments: [
        ("(explode 5)", .unexpectedType(.integer, [.string])),
        ("(explode)", .unexpectedArity(0, .exactly(1))),
        ("(explode \"a\" \"b\")", .unexpectedArity(2, .exactly(1))),
        ("(implode)", .unexpectedArity(0, .atLeast(1))),
        ("(implode \",\")", .unexpectedArity(1, .exactly(2))),
        ("(implode '(\"a\") '(\"b\"))", .unexpectedArity(2, .exactly(1))),
        ("(implode \",\" '(\"a\") '(\"b\"))", .unexpectedArity(3, .exactly(2))),
        ("(implode 5)", .unexpectedType(.integer, [.list])),
        ("(implode \",\" 5)", .unexpectedType(.integer, [.list])),
        ("(implode \",\" \"a\")", .unexpectedType(.string, [.list])),
        ("(string)", .unexpectedArity(0, .exactly(1))),
        ("(string 1 2)", .unexpectedArity(2, .exactly(1))),
        ("(lowercase 5)", .unexpectedType(.integer, [.string])),
        ("(uppercase 5)", .unexpectedType(.integer, [.string])),
        ("(trim 5)", .unexpectedType(.integer, [.string])),
        ("(lowercase)", .unexpectedArity(0, .exactly(1))),
        ("(trim \"a\" \"b\")", .unexpectedArity(2, .exactly(1))),
        ("(lines 5)", .unexpectedType(.integer, [.string])),
        ("(words 5)", .unexpectedType(.integer, [.string])),
        ("(lines)", .unexpectedArity(0, .exactly(1))),
        ("(words)", .unexpectedArity(0, .exactly(1))),
        ("(lines \"a\" \"b\")", .unexpectedArity(2, .exactly(1))),
        ("(words \"a\" \"b\")", .unexpectedArity(2, .exactly(1))),
        ("(split-all \"\" \"abc\")", .cannotBeEmpty),
        ("(split-all \"\" \"\")", .cannotBeEmpty),
        ("(split-all 1 \"a\")", .unexpectedType(.integer, [.string])),
        ("(split-all \",\" 5)", .unexpectedType(.integer, [.string])),
        ("(split-all \",\")", .unexpectedArity(1, .exactly(2))),
        ("(split-all \",\" \"a\" \"b\")", .unexpectedArity(3, .exactly(2))),
        ("(split-once \"\" \"abc\")", .cannotBeEmpty),
        ("(split-once 1 \"a\")", .unexpectedType(.integer, [.string])),
        ("(split-once \",\" 5)", .unexpectedType(.integer, [.string])),
        ("(split-once \",\")", .unexpectedArity(1, .exactly(2))),
        ("(find-first 1 \"a\")", .unexpectedType(.integer, [.string])),
        ("(find-first \"a\" 5)", .unexpectedType(.integer, [.string])),
        ("(find-first \"a\")", .unexpectedArity(1, .exactly(2)))
    ] as [FailureCase])
    func nativeErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    // A signature is only consulted once a second primitive shares its
    // representation, so check each one against calls its body accepts.
    @Test("native string signatures accept what their primitives accept", arguments: [
        ("string.explode", [.string]),
        ("string.implode", [.list]),
        ("string.implode", [.string, .list]),
        ("string.string", [.string]),
        ("string.string", [.integer]),
        ("string.string", [.list]),
        ("string.lowercase", [.string]),
        ("string.uppercase", [.string]),
        ("string.trim", [.string]),
        ("string.lines", [.string]),
        ("string.words", [.string]),
        ("string.split-all", [.string, .string]),
        ("string.split-once", [.string, .string]),
        ("string.find-first", [.string, .string])
    ] as [(String, [MyronValue.Kind])])
    func nativeSignatures(_ name: String, _ kinds: [MyronValue.Kind]) throws {
        let primitive = StandardStrings.primitiveDefinitions.first { p in p.primitiveName == name }
        let signature = try #require(primitive?.signature, "\(name) has no signature")
        guard case .match = try signature.matchesKinds(kinds) else {
            Issue.record("\(name) signature refuses \(kinds)")
            return
        }
    }

    // MARK: - Strings Elsewhere

    @Test("strings work with comparison and predicates")
    func stringsElsewhere() {
        expectValue("(eq (append \"a\" \"b\") \"ab\")", "true")
        expectValue("(string? (head \"abc\"))", "true")
        expectValue("(nothing? (head \"\"))", "true")
        expectValue("(< (head \"abc\") (last \"abc\"))", "true")
    }

    @Test("string functions can be written in Myron")
    func userDefinedStringFunctions() {
        expectValue(
            """
            (define (palindrome? s) (eq s (reverse s)))
            (list (palindrome? "racecar") (palindrome? "abc"))
            """,
            "(true false)")
        expectValue(
            """
            (define (count-char c s) (length (filter (lambda (x) (eq x c)) (explode s))))
            (count-char "l" "hello")
            """,
            "2")
    }

}
