import Testing
import Myron // Imported without @testable to exercise only public API.

// MARK: - Session Environment

@Suite("Session Environment")

struct SessionEnvironmentTests {

    // MARK: Query

    @Test("query finds a name defined in Myron")
    func queryDefined() {
        let session = MyronSession()
        _ = session.eval("(define x 41)")

        #expect(session.query("x")?.asInteger == 41)
    }

    @Test("query finds a name set by the host")
    func querySet() {
        let session = MyronSession()
        session.set("x", to: .integer(41))

        #expect(session.query("x")?.asInteger == 41)
    }

    @Test("query is nil for an unbound name")
    func queryUnbound() {
        #expect(MyronSession().query("nowhere") == nil)
    }

    @Test("query reaches the standard environment")
    func queryStandard() {
        let session = MyronSession()

        #expect(session.query("pi")?.asDouble == Double.pi)
        #expect(session.query("map") != nil)
        #expect(session.query("sqrt")?.kind == .primitive)
    }

    @Test("a name bound to nothing is distinct from an unbound name")
    func queryNothing() {
        let session = MyronSession()
        session.set("n", to: .nothing)

        #expect(session.query("n")?.kind == .nothing)
        #expect(session.query("m") == nil)
    }

    // MARK: Set

    @Test("a value set by the host is visible to Myron")
    func setIsVisible() {
        let session = MyronSession()
        session.set("x", to: .integer(41))

        #expect(session.eval("(+ x 1)").asSuccess?.asInteger == 42)
    }

    @Test("set accepts every kind of data")
    func setAcceptsData() {
        // MyronValue is not Sendable, so it cannot be passed as a test argument.
        let cases: [(MyronValue, String)] = [
            (.boolean(true), "true"),
            (.double(1.5), "1.5"),
            (.integer(7), "7"),
            (.string("a"), "\"a\""),
            (.symbol("s"), "s"),
            (.nothing, "<nothing>"),
            (.list([.integer(1), .integer(2)]), "(1 2)")
        ]

        for (value, expected) in cases {
            let session = MyronSession()
            session.set("v", to: value)
            #expect(session.eval("v").asSuccess?.description == expected)
        }
    }

    @Test("a hashmap set by the host is usable in Myron")
    func setHashmap() {
        let session = MyronSession()
        session.set("hm", to: .hashmap(["k": 1]))

        #expect(session.eval("(get \"k\" hm)").asSuccess?.asInteger == 1)
        #expect(session.eval("(length hm)").asSuccess?.asInteger == 1)
    }

    @Test("a dictionary literal can be set directly")
    func setDictionaryLiteral() {
        let session = MyronSession()
        session.set("cfg", to: ["retries": 3, "name": "x"])

        #expect(session.eval("(length cfg)").asSuccess?.asInteger == 2)
        #expect(session.eval("(get \"retries\" cfg)").asSuccess?.asInteger == 3)
    }

    @Test("set replaces an earlier set")
    func setReplacesSet() {
        let session = MyronSession()
        session.set("x", to: .integer(1))
        session.set("x", to: .integer(2))

        #expect(session.query("x")?.asInteger == 2)
    }

    @Test("set replaces a name defined in Myron")
    func setReplacesDefine() {
        let session = MyronSession()
        _ = session.eval("(define x 1)")
        session.set("x", to: .integer(2))

        #expect(session.eval("x").asSuccess?.asInteger == 2)
    }

    @Test("define replaces a name set by the host")
    func defineReplacesSet() {
        let session = MyronSession()
        session.set("x", to: .integer(1))
        _ = session.eval("(define x 2)")

        #expect(session.query("x")?.asInteger == 2)
    }

    @Test("the host may shadow a standard binding")
    func setShadowsStandard() {
        let session = MyronSession()
        session.set("map", to: .integer(9))

        #expect(session.eval("map").asSuccess?.asInteger == 9)
        #expect(session.query("map")?.asInteger == 9)
    }

    @Test("a value set in one session does not reach another")
    func sessionsAreIndependent() {
        let one = MyronSession()
        let two = MyronSession()
        one.set("x", to: .integer(1))

        #expect(two.query("x") == nil)
        #expect(!two.names.contains("x"))
    }

    // MARK: Names

    @Test("a fresh session has no names")
    func namesFresh() {
        #expect(MyronSession().names.isEmpty)
    }

    @Test("names reports what Myron and the host have bound")
    func namesReportsBindings() {
        let session = MyronSession()
        _ = session.eval("(define x 1)")
        _ = session.eval("(define (f y) y)")
        session.set("h", to: .integer(2))

        #expect(session.names == ["x", "f", "h"])
    }

    @Test("a name bound to nothing is still a name")
    func namesIncludesNothing() {
        let session = MyronSession()
        session.set("n", to: .nothing)

        #expect(session.names.contains("n"))
    }

    @Test("names does not report the standard environment")
    func namesExcludesStandard() {
        // `query` reaches the standard environment but `names` does not, so a
        // name can be resolvable without being listed.
        let session = MyronSession()

        #expect(session.query("pi") != nil)
        #expect(!session.names.contains("pi"))
        #expect(!session.names.contains("map"))
        #expect(!session.names.contains("if"))
    }

    @Test("shadowing a standard name adds it to names")
    func namesAfterShadowing() {
        let session = MyronSession()
        #expect(!session.names.contains("map"))

        _ = session.eval("(define map 5)")
        #expect(session.names.contains("map"))
    }

    @Test("a local binding does not survive in names")
    func namesExcludesLocals() {
        let session = MyronSession()
        _ = session.eval("(let ((tmp 1)) tmp)")
        _ = session.eval("((lambda (arg) arg) 1)")

        #expect(!session.names.contains("tmp"))
        #expect(!session.names.contains("arg"))
    }

    @Test("names grows as bindings are added")
    func namesGrows() {
        let session = MyronSession()
        #expect(session.names.count == 0)

        session.set("a", to: .integer(1))
        #expect(session.names.count == 1)

        _ = session.eval("(define b 2)")
        #expect(session.names.count == 2)

        session.set("a", to: .integer(3))
        #expect(session.names.count == 2)
    }

    // MARK: Values that outlive their session

    @Test("calling a procedure whose session has gone is an error, not a crash")
    func procedureOutlivingItsSession() {
        var donor: MyronSession? = MyronSession()
        _ = donor?.eval("(define n 100)")
        let procedure = donor?.eval("(lambda (x) (+ x n))").asSuccess

        let host = MyronSession()
        host.set("f", to: procedure ?? .nothing)
        #expect(host.eval("(f 1)").asSuccess?.asInteger == 101)

        donor = nil

        let result = host.eval("(f 1)")
        #expect(result.isFailure)
        #expect(result.asFailure?.first?.reason == .containingEnvironmentNoLongerExists)
    }

    @Test("the same holds for a procedure reached through a container")
    func procedureInContainerOutlivingItsSession() {
        var donor: MyronSession? = MyronSession()
        _ = donor?.eval("(define m 7)")
        let procedure = donor?.eval("(lambda (x) (* x m))").asSuccess

        let host = MyronSession()
        host.set("fs", to: .list([procedure ?? .nothing]))
        #expect(host.eval("((head fs) 3)").asSuccess?.asInteger == 21)

        donor = nil

        let result = host.eval("((head fs) 3)")
        #expect(result.isFailure)
        #expect(result.asFailure?.first?.reason == .containingEnvironmentNoLongerExists)
    }

}
