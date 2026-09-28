import Foundation
import Myron

let invocation: Invocation
do {
    invocation = try Invocation.parse(CommandLine.arguments.dropFirst())
} catch {
    Console.error("myron: \(error.description)")
    Console.error(Invocation.usage)
    exit(EXIT_FAILURE)
}

let script = Script(arguments: invocation.arguments)

for load in invocation.loads {
    let status = script.run(path: load.path, mode: load.mode)
    if status != EXIT_SUCCESS { exit(status) }
}

if invocation.repl {
    Repl.run(in: script.session)
}
