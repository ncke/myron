import Foundation
import Myron

// MARK: - Script

enum Script {

    static func run(path: String, in session: MyronSession) -> Int32 {
        let source: String
        do {
            source = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            Console.error("myron: \(error.localizedDescription)")
            return EXIT_FAILURE
        }

        switch session.eval(commentingShebang(source)) {

        case .success, .nothing:
            return EXIT_SUCCESS

        case .failure(let errors):
            for error in errors { Console.error(report(error, in: source, path: path)) }
            return EXIT_FAILURE
        }
    }

}

// MARK: - Shebang

private extension Script {

    static func commentingShebang(_ source: String) -> String {
        guard source.hasPrefix("#!") else { return source }
        return ";!" + source.dropFirst(2)
    }

}

// MARK: - Error Reports

private extension Script {

    static func report(_ error: MyronError, in source: String, path: String) -> String {
        let message = error.message ?? error.reason.description
        guard let location = error.location else { return "\(path): \(message)" }

        let (line, column) = position(of: location.lowerBound, in: source)
        return "\(path):\(line):\(column): \(message)"
    }

    static func position(of offset: Int, in source: String) -> (line: Int, column: Int) {
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

}
