import Foundation
import Testing
import Myron
@testable import MyronRunner

// MARK: - Script

@Suite("Script")

struct ScriptTests {

    // Writes each file into a fresh directory, and gives back that directory.
    private static func files(_ contents: [String: String]) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("myron-script-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (name, text) in contents {
            try text.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        return directory
    }

    private static let resetting = """
        ```lisp
        (define x 1)
        ```

        ```lisp reset-environment
        (define y 2)
        ```
        """

    // MARK: Resetting the Environment

    @Test("a reset leaves the document's later blocks in a clean session")
    func resetInRun() throws {
        let directory = try Self.files(["doc.md": Self.resetting])
        let script = Script(arguments: ["one"])

        let status = script.run(path: directory.appendingPathComponent("doc.md").path, mode: .run)

        #expect(status == EXIT_SUCCESS)
        #expect(script.session.query("x") == nil)
        #expect(script.session.query("y")?.asInteger == 2)
    }

    @Test("a clean session still has the runner's primitives and arguments")
    func resetKeepsRunnerBindings() throws {
        let script = Script(arguments: ["one", "two"])
        _ = script.session.eval("(define x 1)")

        script.resetEnvironment()

        #expect(script.session.query("x") == nil)
        #expect(script.session.query("print") != nil)
        #expect(script.session.query("load") != nil)
        #expect(script.session.eval("arguments").asSuccess?.description == "(\"one\" \"two\")")
    }

    @Test("an earlier load is gone after a document resets")
    func resetForgetsEarlierLoads() throws {
        let directory = try Self.files(["prelude.my": "(define p 1)", "doc.md": Self.resetting])
        let script = Script(arguments: [])

        _ = script.run(path: directory.appendingPathComponent("prelude.my").path, mode: .run)
        #expect(script.session.query("p") != nil)

        _ = script.run(path: directory.appendingPathComponent("doc.md").path, mode: .run)
        #expect(script.session.query("p") == nil)
    }

    @Test("a program cannot load a document that resets the environment")
    func resetInLoad() throws {
        let directory = try Self.files(["doc.md": Self.resetting])
        let script = Script(arguments: [])
        let path = directory.appendingPathComponent("doc.md").path

        #expect {
            try script.load(path: path)
        } throws: { error in
            guard case Script.Failure.resetInLoad = error else { return false }
            return true
        }
    }

    @Test("a document without a reset can be loaded by a program")
    func loadWithoutReset() throws {
        let directory = try Self.files(["doc.md": "```lisp\n(define x 1)\n(+ x 1)\n```"])
        let script = Script(arguments: [])

        let value = try script.load(path: directory.appendingPathComponent("doc.md").path)
        #expect(value.asInteger == 2)
    }

    // MARK: Show

    @Test("show carries on past a failing form")
    func showContinues() throws {
        let directory = try Self.files(["doc.md": "```lisp\n(car 1)\n(define x 1)\n```"])
        let script = Script(arguments: [])

        let status = script.run(path: directory.appendingPathComponent("doc.md").path, mode: .show)

        #expect(status == EXIT_SUCCESS)
        #expect(script.session.query("x")?.asInteger == 1)
    }

    @Test("run stops at a failing form")
    func runStops() throws {
        let directory = try Self.files(["doc.md": "```lisp\n(car 1)\n(define x 1)\n```"])
        let script = Script(arguments: [])

        let status = script.run(path: directory.appendingPathComponent("doc.md").path, mode: .run)

        #expect(status == EXIT_FAILURE)
        #expect(script.session.query("x") == nil)
    }

    @Test("a heading gives the form's place and its source, however many lines")
    func heading() {
        let source = "\n(+ 1\n   2)"
        let location = 1..<source.count
        #expect(Script.heading(at: location, in: source, path: "doc.md") == "doc.md:2:1\n(+ 1\n   2)")
        #expect(Script.heading(at: nil, in: source, path: "doc.md") == "doc.md")
    }

    @Test("an outcome is the value, or the error as it would be reported")
    func outcomes() throws {
        #expect(Script.outcome(of: .success(.integer(3))) == "=> 3")
        #expect(Script.outcome(of: .success(.string("a"))) == "=> \"a\"")

        let failure = MyronSession().eval("(car 1)")
        #expect(Script.outcome(of: failure) == "ERROR: Unrecognised symbol\n(car 1)\n ^^^")
    }

}
