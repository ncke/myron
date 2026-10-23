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
        try define("print", arity: .unspecified) { values in
            values.forEach { value in print(Console.text(of: value), terminator: "") }
            print()
            fflush(nil)
            return MyronValue.nothing
        }

        try define("write", arity: .unspecified) { values in
            values.forEach { value in print(Console.text(of: value), terminator: "") }
            fflush(nil)
            return MyronValue.nothing
        }

        try define("read-line") { () -> MyronValueRepresentable in
            guard let line = Console.readLine() else { return MyronValue.nothing }
            return MyronValue.string(line)
        }

        try define("read-character") { () -> MyronValueRepresentable in
            guard let character = Console.readScalar() else { return MyronValue.nothing }
            return MyronValue.string(character)
        }

        try define("read-all") { () -> MyronValueRepresentable in
            var text = ""
            while let line = Console.readLine(strippingNewline: false) { text += line }
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

// MARK: - Reading Input

private extension Console {

    // A byte read past the end of a character, kept for the next read. The
    // Linux C library declares `stdin` as a mutable global, which Swift 6
    // rejects as shared mutable state, so the byte cannot go back with `ungetc`.
    nonisolated(unsafe) static var pending: Int32?

    static func readByte() -> Int32 {
        if let byte = pending {
            pending = nil
            return byte
        }

        return getchar()
    }

    static func readLine(strippingNewline: Bool = true) -> String? {
        var bytes: [UInt8] = []
        while true {
            let byte = readByte()
            guard byte != EOF else { break }
            bytes.append(UInt8(byte))
            if byte == 0x0A { break }
        }

        guard !bytes.isEmpty else { return nil }

        if strippingNewline, bytes.last == 0x0A {
            bytes.removeLast()
            if bytes.last == 0x0D { bytes.removeLast() }
        }

        return String(decoding: bytes, as: UTF8.self)
    }

    static func readScalar() -> String? {
        let lead = readByte()
        guard lead != EOF else { return nil }

        let length = switch lead {
        case 0xC0...0xDF: 2
        case 0xE0...0xEF: 3
        case 0xF0...0xF7: 4
        default: 1
        }

        var bytes = [UInt8(lead)]
        while bytes.count < length {
            let next = readByte()
            guard next != EOF else { break }
            guard (0x80...0xBF).contains(next) else {
                pending = next
                break
            }

            bytes.append(UInt8(next))
        }

        return String(decoding: bytes, as: UTF8.self)
    }

}
