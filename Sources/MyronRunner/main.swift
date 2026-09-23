import Foundation
import Myron

let path = CommandLine.arguments.dropFirst().first
let scriptArguments = CommandLine.arguments.dropFirst(2)

let session = MyronSession()

do {
    try session.defineConsolePrimitives()
} catch {
    Console.error("myron: \(error)")
    exit(EXIT_FAILURE)
}

session.set("source-file", to: path.map(MyronValue.string) ?? .nothing)
session.set("arguments", to: .list(scriptArguments.map(MyronValue.string)))

if let path {
    exit(Script.run(path: path, in: session))
} else {
    Repl.run(in: session)
}
