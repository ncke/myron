import Testing
@testable import MyronRunner

// MARK: - Invocation

@Suite("Invocation")

struct InvocationTests {

    private static func parse(_ items: [String]) throws(Invocation.UsageError) -> Invocation {
        try Invocation.parse(ArraySlice(items))
    }

    // MARK: Loading

    @Test("--load and --show each take a file, and keep their order")
    func loadsInOrder() throws {
        let invocation = try Self.parse(["--load", "a.my", "--show", "b.md", "--load", "c.md"])
        #expect(invocation.loads == [
            Invocation.Load(path: "a.my", mode: .run),
            Invocation.Load(path: "b.md", mode: .show),
            Invocation.Load(path: "c.md", mode: .run),
        ])
    }

    @Test("--load or --show without a file is a usage error", arguments: ["--load", "--show"])
    func missingFile(option: String) {
        #expect(throws: Invocation.UsageError.self) { try Self.parse([option]) }
    }

    @Test("--show alone is enough to do something")
    func showAlone() throws {
        let invocation = try Self.parse(["--show", "README.md"])
        #expect(!invocation.repl)
        #expect(invocation.loads.count == 1)
    }

    // MARK: Arguments

    @Test("the first plain item starts the arguments, options included")
    func argumentsAfterPlainItem() throws {
        let invocation = try Self.parse(["--show", "a.md", "one", "--show", "b.md"])
        #expect(invocation.loads == [Invocation.Load(path: "a.md", mode: .show)])
        #expect(invocation.arguments == ["one", "--show", "b.md"])
    }

    @Test("an unknown option or nothing to do is a usage error", arguments: [["--bogus"], [], ["one"]])
    func usageErrors(items: [String]) {
        #expect(throws: Invocation.UsageError.self) { try Self.parse(items) }
    }

}
