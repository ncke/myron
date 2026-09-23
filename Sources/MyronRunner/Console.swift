import Foundation
import Myron

// MARK: - Console

enum Console {

    static func error(_ text: String) {
        fflush(nil)
        FileHandle.standardError.write(Data((text + "\n").utf8))
    }

    static func text(of value: MyronValue) -> String {
        value.asString ?? value.description
    }

}

// MARK: - Console Primitives

extension MyronSession {

    func defineConsolePrimitives() throws {
        try define("print") { value in
            print(Console.text(of: value))
            fflush(nil)
            return MyronValue.nothing
        }

        try define("write") { value in
            print(Console.text(of: value), terminator: "")
            fflush(nil)
            return MyronValue.nothing
        }

        try define("read-line") { () -> MyronValueRepresentable in
            guard let line = readLine() else { return MyronValue.nothing }
            return MyronValue.string(line)
        }

        try define("read-character") { () -> MyronValueRepresentable in
            guard let character = Console.readScalar() else { return MyronValue.nothing }
            return MyronValue.string(character)
        }

        try define("read-all") { () -> MyronValueRepresentable in
            var text = ""
            while let line = readLine(strippingNewline: false) { text += line }
            return MyronValue.string(text)
        }

        try define("exit") { status in
            let code = try status.requireInteger()
            guard (0...255).contains(code) else {
                throw MyronHostError("exit status must be from 0 to 255, got \(code)")
            }

            exit(Int32(code))
        }
    }

}

// MARK: - Reading Characters

private extension Console {

    static func readScalar() -> String? {
        let lead = getchar()
        guard lead != EOF else { return nil }

        let length = switch lead {
        case 0xC0...0xDF: 2
        case 0xE0...0xEF: 3
        case 0xF0...0xF7: 4
        default: 1
        }

        var bytes = [UInt8(lead)]
        while bytes.count < length {
            let next = getchar()
            guard next != EOF else { break }
            guard (0x80...0xBF).contains(next) else {
                ungetc(next, stdin)
                break
            }

            bytes.append(UInt8(next))
        }

        return String(decoding: bytes, as: UTF8.self)
    }

}
