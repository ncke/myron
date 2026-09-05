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
        ("(contains \"ll\" \"hello\")", "true"),
        ("(contains \"hello\" \"hello\")", "true"),
        ("(contains \"x\" \"hello\")", "false"),
        ("(contains \"lo\" \"hel\")", "false"),
        ("(contains \"\" \"hello\")", "true"),
        ("(contains \"\" \"\")", "true"),
        ("(contains \"a\" \"\")", "false"),
        ("(contains \"LL\" \"hello\")", "false")
    ] as [ValueCase])
    func contains(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("contains on a string differs from contains on its characters")
    func containsSubstringVersusElement() {
        expectValue("(contains \"ab\" \"abc\")", "true")
        expectValue("(contains \"ab\" (explode \"abc\"))", "false")
    }

    @Test("sequence errors over strings", arguments: [
        ("(take -1 \"ab\")", .cannotBeNegative),
        ("(drop -1 \"ab\")", .cannotBeNegative),
        ("(take \"x\" \"ab\")", .typeMismatch),
        ("(drop \"x\" \"ab\")", .typeMismatch),
        ("(nth \"a\" \"abc\")", .typeMismatch),
        ("(nth 3 \"abc\")", .subscriptOutOfBounds(3, 3)),
        ("(nth -1 \"abc\")", .subscriptOutOfBounds(-1, 3)),
        ("(nth 0 \"\")", .subscriptOutOfBounds(0, 0)),
        ("(contains 1 \"abc\")", .typeMismatch),
        ("(append \"a\" 1)", .typeMismatch)
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

    @Test("native string errors", arguments: [
        ("(explode 5)", .typeMismatch),
        ("(explode)", .unexpectedArity),
        ("(explode \"a\" \"b\")", .unexpectedArity),
        ("(implode)", .unexpectedArity),
        ("(implode \",\")", .unexpectedArity),
        ("(implode '(\"a\") '(\"b\"))", .unexpectedArity),
        ("(implode \",\" '(\"a\") '(\"b\"))", .unexpectedArity),
        ("(implode 5)", .expectedList),
        ("(implode \",\" 5)", .expectedList),
        ("(implode \",\" \"a\")", .expectedList),
        ("(string)", .unexpectedArity),
        ("(string 1 2)", .unexpectedArity),
        ("(lowercase 5)", .typeMismatch),
        ("(uppercase 5)", .typeMismatch),
        ("(trim 5)", .typeMismatch),
        ("(lowercase)", .unexpectedArity),
        ("(trim \"a\" \"b\")", .unexpectedArity),
        ("(lines 5)", .typeMismatch),
        ("(words 5)", .typeMismatch),
        ("(lines)", .unexpectedArity),
        ("(words)", .unexpectedArity),
        ("(lines \"a\" \"b\")", .unexpectedArity),
        ("(words \"a\" \"b\")", .unexpectedArity)
    ] as [FailureCase])
    func nativeErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
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
