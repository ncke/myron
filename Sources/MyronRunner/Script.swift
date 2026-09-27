import Foundation
import Myron

// MARK: - Script

// Loads files into a session, both for `--load` on the command line and for the
// `load` primitive. The session is held weakly, since the primitive holds this.
final class Script: @unchecked Sendable {
    private weak var session: MyronSession?
    private var loading = Set<String>()

    init(session: MyronSession) {
        self.session = session
    }

    // Loads a file named on the command line.
    func run(path: String) -> Int32 {
        do {
            _ = try load(path: path)
            return EXIT_SUCCESS
        } catch {
            for report in error.reports { Console.error(report) }
            return EXIT_FAILURE
        }
    }

    // Evaluates a file into the session and returns the value of its last form.
    func load(path: String) throws(Failure) -> MyronValue {
        guard let session else { return .nothing }

        let key = URL(fileURLWithPath: path).standardizedFileURL.path
        guard !loading.contains(key) else { throw .cyclic(path) }

        let source: String
        do {
            source = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            throw .unreadable(error.localizedDescription)
        }

        loading.insert(key)
        defer { loading.remove(key) }

        switch session.eval(commentingShebang(source)) {
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
        case failed(String, String, [MyronError])

        // In full, for the command line: each error with its caret.
        var reports: [String] {
            switch self {
            case .unreadable(let description):
                return ["myron: \(description)"]
            case .cyclic(let path):
                return ["myron: \(path) is already loading"]
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

    func defineLoadPrimitive(using script: Script) throws {
        try define("load") { (value: MyronValue) -> MyronValueRepresentable in
            let path = try value.requireString()
            do throws(Script.Failure) {
                return try script.load(path: path)
            } catch {
                throw MyronHostError("load: \(error.summary)")
            }
        }
    }

}

// MARK: - Shebang

private extension Script {

    func commentingShebang(_ source: String) -> String {
        guard source.hasPrefix("#!") else { return source }
        return ";!" + source.dropFirst(2)
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
