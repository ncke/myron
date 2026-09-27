import Foundation

// MARK: - Invocation

struct Invocation {
    var repl = false
    var paths = [String]()
    var arguments = [String]()

    static let usage = "usage: myron [--repl] [--load file]... [argument ...]"

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
            case "--load":
                remaining.removeFirst()
                guard let path = remaining.popFirst() else {
                    throw UsageError(description: "--load needs a file")
                }
                invocation.paths.append(path)
            case _ where argument.hasPrefix("-"):
                throw UsageError(description: "unknown option: \(argument)")
            default:
                invocation.arguments = Array(remaining)
                remaining = []
            }
        }

        guard invocation.repl || !invocation.paths.isEmpty else {
            throw UsageError(description: "nothing to do: give --load file, or --repl")
        }

        return invocation
    }

}
