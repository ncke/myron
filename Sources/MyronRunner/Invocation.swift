import Foundation

// MARK: - Invocation

struct Invocation {
    var repl = false
    var loads = [Load]()
    var arguments = [String]()

    struct Load: Equatable {
        let path: String
        let mode: Script.Mode
    }

    static let usage = "usage: myron [--repl] [--load file | --show file]... [argument ...]"

}

// MARK: - Parsing

extension Invocation {

    struct UsageError: Error {
        let description: String
    }

    // Options come first. The first plain item, or anything after `--`, starts
    // the arguments, so a script's own arguments are never taken as options.
    static func parse(_ commandLine: ArraySlice<String>) throws(UsageError) -> Invocation {
        var invocation = Invocation()
        var remaining = commandLine

        while let argument = remaining.first {
            switch argument {
            case "--":
                remaining.removeFirst()
                invocation.arguments = Array(remaining)
                remaining = []
            case "--repl":
                remaining.removeFirst()
                invocation.repl = true
            case "--load", "--show":
                remaining.removeFirst()
                guard let path = remaining.popFirst() else {
                    throw UsageError(description: "\(argument) needs a file")
                }
                let mode = argument == "--show" ? Script.Mode.show : .run
                invocation.loads.append(Load(path: path, mode: mode))
            case _ where argument.hasPrefix("-"):
                throw UsageError(description: "unknown option: \(argument)")
            default:
                invocation.arguments = Array(remaining)
                remaining = []
            }
        }

        guard invocation.repl || !invocation.loads.isEmpty else {
            throw UsageError(description: "nothing to do: give --load file, --show file, or --repl")
        }

        return invocation
    }

}
