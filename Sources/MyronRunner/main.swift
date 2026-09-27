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

let session = MyronSession()
let script = Script(session: session)

do {
    try session.defineConsolePrimitives()
    try session.defineLoadPrimitive(using: script)
} catch {
    Console.error("myron: \(error)")
    exit(EXIT_FAILURE)
}

session.set("arguments", to: .list(invocation.arguments.map(MyronValue.string)))

for path in invocation.paths {
    let status = script.run(path: path)
    if status != EXIT_SUCCESS { exit(status) }
}

if invocation.repl {
    Repl.run(in: session)
}
