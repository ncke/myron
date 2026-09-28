import Foundation
import Myron

// MARK: - Script

// Loads files for `--load` and `--show` on the command line, and for the `load`
// primitive. It owns the session, since a literate document can replace it.
final class Script: @unchecked Sendable {
    private(set) var session = MyronSession()
    private let arguments: [String]
    private var loading = Set<String>()

    enum Mode {
        case run  // Evaluate as a program.
        case show // Evaluate form by form, printing each result.
    }

    init(arguments: [String]) {
        self.arguments = arguments
        resetEnvironment()
    }

    // A clean session, with the runner's own primitives and bindings.
    func resetEnvironment() {
        let session = MyronSession()
        do {
            try session.defineConsolePrimitives()
            try session.defineLoadPrimitive(using: self)
        } catch {
            fatalError("myron: cannot define the runner's primitives: \(error)")
        }

        session.set("arguments", to: .list(arguments.map(MyronValue.string)))
        self.session = session
    }

    // Loads a file named on the command line. A literate document starts a clean
    // session at each block marked to reset the environment.
    func run(path: String, mode: Mode) -> Int32 {
        do throws(Failure) {
            let key = Self.key(for: path)
            let segments = try read(path)

            loading.insert(key)
            defer { loading.remove(key) }

            for (index, source) in segments.enumerated() {
                if index > 0 { resetEnvironment() }

                switch mode {
                case .run:
                    if case .failure(let errors) = session.eval(source) {
                        throw .failed(path, source, errors)
                    }
                case .show:
                    show(source, path: path)
                }
            }

            return EXIT_SUCCESS

        } catch {
            for report in error.reports { Console.error(report) }
            return EXIT_FAILURE
        }
    }

    // Evaluates a file into the session and returns the value of its last form.
    // A program cannot reset the environment it is running in.
    func load(path: String) throws(Failure) -> MyronValue {
        let key = Self.key(for: path)
        guard !loading.contains(key) else { throw .cyclic(path) }

        let segments = try read(path)
        guard segments.count == 1, let source = segments.first else {
            throw .resetInLoad(path)
        }

        loading.insert(key)
        defer { loading.remove(key) }

        switch session.eval(source) {
        case .success(let value): return value
        case .nothing: return .nothing
        case .failure(let errors): throw .failed(path, source, errors)
        }
    }

}

// MARK: - Failure

extension Script {

    enum Failure: Error {
        case unreadable(String)
        case cyclic(String)
        case resetInLoad(String)
        case failed(String, String, [MyronError])

        // In full, for the command line: each error with its caret.
        var reports: [String] {
            switch self {
            case .unreadable(let description):
                return ["myron: \(description)"]
            case .cyclic(let path):
                return ["myron: \(path) is already loading"]
            case .resetInLoad(let path):
                return ["myron: \(path) resets the environment, so cannot be loaded by a program"]
            case .failed(let path, let source, let errors):
                return errors.map { error in
                    report(
                        error,
                        message: error.message ?? error.reason.description,
                        in: source,
                        path: path)
                }
            }
        }

        // On one line, for `load`, whose own failure carries the caret.
        var summary: String {
            switch self {
            case .unreadable(let description):
                return description
            case .cyclic(let path):
                return "\(path) is already loading"
            case .resetInLoad(let path):
                return "\(path) resets the environment, so cannot be loaded by a program"
            case .failed(let path, let source, let errors):
                return errors.map { error in
                    report(error, message: error.reason.description, in: source, path: path)
                }.joined(separator: "; ")
            }
        }
    }

}

// MARK: - Load Primitive

extension MyronSession {

    // Weak, since the script holds the session that holds this primitive.
    func defineLoadPrimitive(using script: Script) throws {
        try define("load") { [weak script] (value: MyronValue) -> MyronValueRepresentable in
            let path = try value.requireString()
            guard let script else { return MyronValue.nothing }
            do throws(Script.Failure) {
                return try script.load(path: path)
            } catch {
                throw MyronHostError("load: \(error.summary)")
            }
        }
    }

}

// MARK: - Source Preparation

private extension Script {

    static let markdownExtensions: Set<String> = ["md", "markdown"]

    static func key(for path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }

    // The file's source, one per environment: a program is always a single one.
    func read(_ path: String) throws(Failure) -> [String] {
        let text: String
        do {
            text = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw .unreadable(error.localizedDescription)
        }

        return Self.isMarkdown(path)
            ? Literate.segments(fromMarkdown: text)
            : [commentingShebang(text)]
    }

    static func isMarkdown(_ path: String) -> Bool {
        markdownExtensions.contains(URL(fileURLWithPath: path).pathExtension.lowercased())
    }

    func commentingShebang(_ source: String) -> String {
        guard source.hasPrefix("#!") else { return source }
        return ";!" + source.dropFirst(2)
    }

}

// MARK: - Show

extension Script {

    // Each form's place and source, then whatever it writes, then its result.
    func show(_ source: String, path: String) {
        var announced = false
        _ = session.evalEach(
            source,
            willEvaluate: { location in
                print(Self.heading(at: location, in: source, path: path))
                fflush(nil)
                announced = true
            },
            didEvaluate: { formResult in
                if !announced { print(Self.place(of: formResult.location, in: source, path: path)) }
                print(Self.outcome(of: formResult.result))
                print()
                fflush(nil)
                announced = false
            })
    }

    static func heading(at location: MyronLocation?, in source: String, path: String) -> String {
        let place = place(of: location, in: source, path: path)
        guard let location else { return place }
        return place + "\n" + source.dropFirst(location.lowerBound).prefix(location.count)
    }

    static func place(of location: MyronLocation?, in source: String, path: String) -> String {
        guard let location else { return path }
        let (line, column) = position(of: location.lowerBound, in: source)
        return "\(path):\(line):\(column)"
    }

    static func outcome(of result: MyronResult) -> String {
        switch result {
        case .success(let value):
            return "=> \(value)"
        case .failure(let errors):
            return errors.map { error in error.message ?? error.reason.description }.joined(separator: "\n")
        case .nothing:
            return "=> nothing"
        }
    }

}

// MARK: - Error Reports

private func report(
    _ error: MyronError,
    message: String,
    in source: String,
    path: String
) -> String {
    guard let location = error.location else { return "\(path): \(message)" }

    let (line, column) = position(of: location.lowerBound, in: source)
    return "\(path):\(line):\(column): \(message)"
}

private func position(of offset: Int, in source: String) -> (line: Int, column: Int) {
    var line = 1
    var column = 1
    for character in source.prefix(offset) {
        if character.isNewline {
            line += 1
            column = 1
        } else {
            column += 1
        }
    }

    return (line, column)
}
