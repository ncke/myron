import Testing
@testable import Myron

// MARK: - Ordering

@Suite("Standard Ordering")

struct StandardOrderingTests {

    @Test("sort", arguments: [
        ("(sort '(3 1 2))", "(1 2 3)"),
        ("(sort '(1 2 3))", "(1 2 3)"),
        ("(sort '(3 2 1))", "(1 2 3)"),
        ("(sort '(3 1 3 2 1))", "(1 1 2 3 3)"),
        ("(sort '(-1 0 -5))", "(-5 -1 0)"),
        ("(sort '(2.5 1.0 1.5))", "(1.0 1.5 2.5)"),
        ("(sort '(\"b\" \"a\" \"c\"))", "(\"a\" \"b\" \"c\")"),
        ("(sort '(\"b\" \"B\" \"a\"))", "(\"B\" \"a\" \"b\")"),
        ("(sort '(1))", "(1)"),
        ("(sort '())", "()")
    ] as [ValueCase])
    func sort(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("sort-descending", arguments: [
        ("(sort-descending '(1 3 2))", "(3 2 1)"),
        ("(sort-descending '(1 3 1 2))", "(3 2 1 1)"),
        ("(sort-descending '(1.5 2.5 1.0))", "(2.5 1.5 1.0)"),
        ("(sort-descending '(\"a\" \"c\" \"b\"))", "(\"c\" \"b\" \"a\")"),
        ("(sort-descending '(1))", "(1)"),
        ("(sort-descending '())", "()")
    ] as [ValueCase])
    func sortDescending(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a set sorts into a list", arguments: [
        ("(sort (set 3 1 2))", "(1 2 3)"),
        ("(sort-descending (set 3 1 2))", "(3 2 1)"),
        ("(sort (set))", "()")
    ] as [ValueCase])
    func sortingASet(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("a nan sorts after every other double", arguments: [
        ("(sort (list 2.0 nan 1.0))", "(1.0 2.0 nan)"),
        ("(sort (list nan 2.0 nan 1.0))", "(1.0 2.0 nan nan)"),
        ("(sort (list nan infinity 0.0))", "(0.0 inf nan)"),
        ("(sort (list nan))", "(nan)"),
        ("(sort-descending (list 2.0 nan 1.0))", "(nan 2.0 1.0)"),
        ("(sort-descending (list nan 2.0 nan 1.0))", "(nan nan 2.0 1.0)")
    ] as [ValueCase])
    func sortingNaN(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("sorting leaves its argument alone", arguments: [
        ("(let ((xs '(3 1 2))) (begin (sort xs) xs))", "(3 1 2)"),
        ("(let ((xs '(3 1 2))) (eq (reverse (sort xs)) (sort-descending xs)))", "true")
    ] as [ValueCase])
    func sortingIsPure(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("sort errors", arguments: [
        ("(sort)", .unexpectedArity(0, .exactly(1))),
        ("(sort '(1) '(2))", .unexpectedArity(2, .exactly(1))),
        ("(sort-descending)", .unexpectedArity(0, .exactly(1))),
        ("(sort 5)", .unexpectedType(.integer, [.list, .set])),
        ("(sort \"cba\")", .unexpectedType(.string, [.list, .set])),
        ("(sort '(true false))", .incomparableTypes),
        ("(sort-descending '(true false))", .incomparableTypes),
        ("(sort (list '(2) '(1)))", .incomparableTypes)
    ] as [FailureCase])
    func sortErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

    @Test("sorting mixed kinds fails", arguments: [
        "(sort '(1 2.0))",
        "(sort '(\"a\" 1))",
        "(sort-descending '(1 \"a\" 2))"
    ])
    func sortMixedKinds(_ source: String) {
        expectFailure(source)
    }

    @Test("sortable?", arguments: [
        ("(sortable? '(3 1 2))", "true"),
        ("(sortable? '(1.0 2.0))", "true"),
        ("(sortable? '(\"a\" \"b\"))", "true"),
        ("(sortable? (set 1 2))", "true"),
        ("(sortable? (set))", "true"),
        ("(sortable? (set 1 2.0))", "false"),
        ("(sortable? (list 1.0 nan))", "true"),
        ("(sortable? '(1))", "true"),
        ("(sortable? '())", "true"),
        ("(sortable? '(1 2.0))", "false"),
        ("(sortable? '(1 \"a\"))", "false"),
        ("(sortable? '(true false))", "false"),
        ("(sortable? (list '(1) '(2)))", "false"),
        ("(sortable? (list nothing))", "false")
    ] as [ValueCase])
    func isSortable(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("sortable? is false for anything but a list or set", arguments: [
        ("(sortable? 5)", "false"),
        ("(sortable? 1.0)", "false"),
        ("(sortable? \"abc\")", "false"),
        ("(sortable? true)", "false"),
        ("(sortable? 'a)", "false"),
        ("(sortable? nothing)", "false"),
        ("(sortable? (make-hashmap))", "false"),
        ("(sortable? sort)", "false"),
        ("(sortable? (lambda (x) x))", "false")
    ] as [ValueCase])
    func sortableRejectsNonCollections(_ c: ValueCase) {
        expectValue(c.source, c.expected)
    }

    @Test("sortable? agrees with sort", arguments: [
        "'(3 1 2)", "'(\"b\" \"a\")", "'()", "'(1 2.0)", "'(true false)",
        "(set 2 1)", "(set 1 2.0)", "(list 1.0 nan)", "5", "\"cba\"", "nothing"
    ])
    func sortableAgreesWithSort(_ list: String) {
        let sortable = MyronSession().eval("(sortable? \(list))")
        let sorted = MyronSession().eval("(sort \(list))")

        guard case .success(let answer) = sortable else {
            Issue.record("(sortable? \(list)) did not succeed")
            return
        }

        switch sorted {
        case .success: #expect(answer.description == "true")
        case .failure: #expect(answer.description == "false")
        case .nothing: Issue.record("(sort \(list)) got nothing")
        }
    }

    @Test("sortable? errors", arguments: [
        ("(sortable?)", .unexpectedArity(0, .exactly(1))),
        ("(sortable? '(1) '(2))", .unexpectedArity(2, .exactly(1)))
    ] as [FailureCase])
    func sortableErrors(_ c: FailureCase) {
        expectFailure(c.source, reason: c.reason)
    }

}
