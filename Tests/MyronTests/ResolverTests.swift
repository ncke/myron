import Testing
@testable import Myron

// MARK: - Resolver

@Suite("Standard Resolver")

struct StandardResolverTests {

    private typealias Signature = StandardSignature
    private typealias Constraint = StandardSignature.Constraint

    private static func primitive(
        _ name: String,
        _ signature: StandardSignature,
        yielding result: String
    ) -> MyronPrimitive {
        return MyronPrimitive(
            primitiveName: name,
            representations: ["r"],
            signature: signature,
            body: { _, _ in .string(result) })
    }

    private static func resolve(
        _ primitives: [MyronPrimitive],
        _ args: [MyronValue]
    ) throws -> MyronValue {
        let resolver = StandardResolver.make(representation: "r", primitives: primitives)
        return try resolver.call(args, at: nil)
    }

    // MARK: Specificity

    @Test("a narrower signature wins over a wider one, whichever registers first")
    func narrowerWins() throws {
        let narrow = Self.primitive("a.r", Signature([Signature.list1]), yielding: "narrow")
        let wide = Self.primitive("b.r", Signature([Signature.any1]), yielding: "wide")

        for order in [[narrow, wide], [wide, narrow]] {
            #expect(try Self.resolve(order, [.list([])]).description == "\"narrow\"")
            #expect(try Self.resolve(order, [.integer(1)]).description == "\"wide\"")
        }
    }

    @Test("specificity is a strict partial order")
    func specificityOrdering() throws {
        let narrow: [Constraint] = [.subset([.list])]
        let wide: [Constraint] = [.any]

        #expect(try Signature.compareSpecificity(narrow, to: wide) == .moreSpecific)
        #expect(try Signature.compareSpecificity(wide, to: narrow) == .lessSpecific)
        #expect(try Signature.compareSpecificity(narrow, to: narrow) == .equallySpecific)

        // Narrowing one position while widening another settles nothing.
        let leftNarrow: [Constraint] = [.subset([.list]), .any]
        let rightNarrow: [Constraint] = [.any, .subset([.string])]
        #expect(try Signature.compareSpecificity(leftNarrow, to: rightNarrow) == .incomparable)
        #expect(try Signature.compareSpecificity(rightNarrow, to: leftNarrow) == .incomparable)

        // Disjoint kinds are incomparable however many each side lists.
        let one: [Constraint] = [.subset([.list])]
        let threeOthers: [Constraint] = [.subset([.string, .integer, .double])]
        #expect(try Signature.compareSpecificity(one, to: threeOthers) == .incomparable)

        // A true subset is narrower.
        let superset: [Constraint] = [.subset([.list, .string, .integer])]
        #expect(try Signature.compareSpecificity(one, to: superset) == .moreSpecific)
    }

    // MARK: Ambiguity

    @Test("identical signatures are ambiguous, whichever registers first")
    func identicalSignaturesAreAmbiguous() throws {
        let first = Self.primitive("a.r", Signature([Signature.list1]), yielding: "first")
        let second = Self.primitive("b.r", Signature([Signature.list1]), yielding: "second")

        for order in [[first, second], [second, first]] {
            #expect(throws: MyronError.self) { try Self.resolve(order, [.list([])]) }
        }
    }

    @Test("signatures that narrow in different places are ambiguous")
    func crossSpecificSignaturesAreAmbiguous() throws {
        let leftNarrow = Self.primitive(
            "a.r",
            Signature([(.exactly(1), .subset([.list])), Signature.any1]),
            yielding: "left")
        let rightNarrow = Self.primitive(
            "b.r",
            Signature([Signature.any1, (.exactly(1), .subset([.string]))]),
            yielding: "right")

        for order in [[leftNarrow, rightNarrow], [rightNarrow, leftNarrow]] {
            #expect(throws: MyronError.self) {
                try Self.resolve(order, [.list([]), .string("s")])
            }
        }
    }

    @Test("an ambiguity names only the contenders that tie")
    func ambiguityNamesContenders() throws {
        let first = Self.primitive("a.r", Signature([Signature.list1]), yielding: "first")
        let second = Self.primitive("b.r", Signature([Signature.list1]), yielding: "second")
        let dominated = Self.primitive("c.r", Signature([Signature.any1]), yielding: "wide")

        do {
            _ = try Self.resolve([dominated, first, second], [.list([])])
            Issue.record("expected an ambiguity")

        } catch let error as MyronError {
            guard case .ambiguousResolution(_, _, let contenders) = error.reason else {
                Issue.record("expected an ambiguity, got \(error.reason)")
                return
            }

            #expect(contenders == ["a.r", "b.r"])
        }
    }

    // MARK: Arity

    @Test("a fixed signature reports the arity it wants")
    func fixedArity() throws {
        let fixed = Self.primitive("a.r", Signature([Signature.list1]), yielding: "fixed")

        for args in [[], [MyronValue.list([]), .list([])]] {
            do {
                _ = try Self.resolve([fixed], args)
                Issue.record("expected an arity error for \(args.count) arguments")

            } catch let error as MyronError {
                #expect(error.reason == .unexpectedArity(args.count, .exactly(1)))
            }
        }
    }

    @Test("a variadic signature reports a minimum arity")
    func variadicArity() throws {
        let variadic = Self.primitive(
            "a.r",
            Signature([Signature.str1], allowsVariadic: .homogenous),
            yielding: "variadic")

        do {
            _ = try Self.resolve([variadic], [])
            Issue.record("expected an arity error")

        } catch let error as MyronError {
            #expect(error.reason == .unexpectedArity(0, .atLeast(1)))
        }
    }

    @Test("a variadic signature constrains its surplus arguments")
    func variadicSurplus() throws {
        let variadic = Self.primitive(
            "a.r",
            Signature([Signature.str1], allowsVariadic: .homogenous),
            yielding: "variadic")

        let strings: [MyronValue] = [.string("a"), .string("b"), .string("c")]
        #expect(try Self.resolve([variadic], strings).description == "\"variadic\"")

        do {
            _ = try Self.resolve([variadic], [.string("a"), .integer(1)])
            Issue.record("expected a type error for the surplus argument")

        } catch let error as MyronError {
            #expect(error.reason == .unexpectedType(.integer, [.string]))
        }
    }

    @Test("a heterogenous signature accepts any surplus arguments")
    func heterogenousSurplus() throws {
        let variadic = Self.primitive(
            "a.r",
            Signature([Signature.str1], allowsVariadic: .heterogenous),
            yielding: "variadic")

        for args: [MyronValue] in [
            [.string("a")],
            [.string("a"), .integer(1)],
            [.string("a"), .integer(1), .list([]), .nothing]
        ] {
            #expect(try Self.resolve([variadic], args).description == "\"variadic\"")
        }
    }

    @Test("a heterogenous signature still constrains its fixed terms")
    func heterogenousFixedTerms() throws {
        let variadic = Self.primitive(
            "a.r",
            Signature([Signature.str1], allowsVariadic: .heterogenous),
            yielding: "variadic")

        do {
            _ = try Self.resolve([variadic], [])
            Issue.record("expected an arity error")

        } catch let error as MyronError {
            #expect(error.reason == .unexpectedArity(0, .atLeast(1)))
        }

        do {
            _ = try Self.resolve([variadic], [.integer(1), .string("a")])
            Issue.record("expected a type error for the fixed argument")

        } catch let error as MyronError {
            #expect(error.reason == .unexpectedType(.integer, [.string]))
        }
    }

    @Test("a heterogenous signature resolves against a fixed one by its fixed terms")
    func heterogenousAgainstFixed() throws {
        let variadic = Self.primitive(
            "a.r",
            Signature([Signature.str1], allowsVariadic: .heterogenous),
            yielding: "variadic")
        let fixed = Self.primitive("b.r", Signature([Signature.list1]), yielding: "fixed")

        for order in [[variadic, fixed], [fixed, variadic]] {
            #expect(try Self.resolve(order, [.string("a"), .integer(1)]).description
                    == "\"variadic\"")
            #expect(try Self.resolve(order, [.list([])]).description == "\"fixed\"")
        }
    }

    // MARK: Described Forms

    @Test("a form is described for every combination of kinds")
    func describedForms() throws {
        let twoByTwo = Signature([
            (.exactly(1), .subset([.list, .string])),
            (.exactly(1), .subset([.integer, .double]))])

        #expect(try twoByTwo.describeForms(representation: "f") == [
            "f list integer", "f list double", "f string integer", "f string double"
        ])

        let withAny = Signature([Signature.any1, (.exactly(1), .subset([.list, .string]))])
        #expect(try withAny.describeForms(representation: "f") == ["f any list", "f any string"])
    }

    @Test("a repeated term repeats its kind within the form")
    func describedMultiples() throws {
        let pair = Signature([(.exactly(2), .subset([.list, .string]))])
        #expect(try pair.describeForms(representation: "f") == ["f list list", "f string string"])
    }

    @Test("a variadic form marks its surplus")
    func describedVariadic() throws {
        let variadic = Signature([Signature.list1], allowsVariadic: .homogenous)
        #expect(try variadic.describeForms(representation: "append") == ["append list ..."])

        let heterogenous = Signature([Signature.list1], allowsVariadic: .heterogenous)
        #expect(try heterogenous.describeForms(representation: "f") == ["f list ..."])

        let fixed = Signature([Signature.list1])
        #expect(try fixed.describeForms(representation: "head") == ["head list"])
    }

}
