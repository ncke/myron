import Foundation

// MARK: - Strings

// MARK: - Sequence

struct StandardStrings {

    static func head(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        guard let head = str.first else { return .nothing }
        return .string(String(head))
    }

    static func tail(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        let tail = String(str.dropFirst())
        return .string(tail)
    }

    static func initial(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        let result = String(str.dropLast())
        return .string(result)
    }

    static func last(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        guard let last = str.last else { return .nothing }
        return .string(String(last))
    }

    static func take(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let count = try fst.unwrapInteger(location)
        guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

        let str = try snd.unwrapString(location)
        let take = String(str.prefix(count))
        return .string(take)
    }

    static func drop(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let count = try fst.unwrapInteger(location)
        guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

        let str = try snd.unwrapString(location)
        let drop = String(str.dropFirst(count))
        return .string(drop)
    }

    static func length(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        return .integer(str.count)
    }

    static func empty(args: [Value], location: Location?) throws -> Value {
        let n = try length(args: args, location: location).unwrapInteger(location)
        return .boolean(n == 0)
    }

    static func append(args: [Value], location: Location?) throws -> Value {
        try args.mustHaveAtLeast(1, location)
        var result = ""
        for arg in args {
            let str = try arg.unwrapString(location)
            result += str
        }
        return .string(result)
    }

    static func reverse(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        return .string(String(str.reversed()))
    }

    static func nth(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let index = try fst.unwrapInteger(location)
        let str = try snd.unwrapString(location)

        guard index >= 0, index < str.count else {
            throw MyronError(.subscriptOutOfBounds(index, str.count), at: location)
        }

        let char = str[str.index(str.startIndex, offsetBy: index)]
        return .string(String(char))
    }

    static func contains(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let target = try fst.unwrapString(location)
        let str = try snd.unwrapString(location)
        if target.isEmpty { return .boolean(true) }
        return .boolean(str.contains(target))
    }

}

// MARK: - String Native

extension StandardStrings {

    static func explode(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        let pieces = str.map { ch in Value.string(String(ch)) }
        return .list(pieces)
    }

    static func implode(args: [Value], location: Location?) throws -> Value {
        try args.mustHaveAtLeast(1, location)
        let sep: String
        let elements: [Value]

        if args[0].kind == .string {
            guard args.count == 2 else {
                throw MyronError(.unexpectedArity(args.count, .exactly(2)), at: location)
            }
            sep = try args[0].unwrapString(location)
            elements = try args[1].unwrapList(location)
        } else {
            guard args.count == 1 else {
                throw MyronError(.unexpectedArity(args.count, .exactly(1)), at: location)
            }
            sep = ""
            elements = try args[0].self.unwrapList(location)
        }

        let descriptions = elements.map { element in
            switch element {
            case .string(let str): return str
            default: return element.description
            }
        }

        return .string(descriptions.joined(separator: sep))
    }

    static func string(args: [Value], location: Location?) throws -> Value {
        let src = try args.unwrap1(location)
        if src.kind == .string { return src }
        return .string(src.description)
    }

    static func lowercase(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        return .string(str.lowercased())
    }

    static func uppercase(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        return .string(str.uppercased())
    }

    static func trim(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        return .string(str.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func lines(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        let lines = str
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map { lineStr in Value.string(String(lineStr)) }

        return .list(lines)
    }

    static func words(args: [Value], location: Location?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        let words = str
            .split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            .map { wordStr in Value.string(String(wordStr)) }

        return .list(words)
    }

}
