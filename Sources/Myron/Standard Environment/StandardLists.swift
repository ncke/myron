import Foundation

// MARK: - Standard Lists

// MARK: - Sequence

struct StandardLists {

    static func head(args: [Value], location: Location?) throws -> Value {
        let elements = try args.unwrap1(location).unwrapList(location)
        guard let head = elements.first else { return .nothing }
        return head
    }

    static func tail(args: [Value], location: Location?) throws -> Value {
        let elements = try args.unwrap1(location).unwrapList(location)
        let tail = Array(elements.dropFirst())
        return .list(tail)
    }

    static func initial(args: [Value], location: Location?) throws -> Value {
        let elements = try args.unwrap1(location).unwrapList(location)
        let result = Array(elements.dropLast())
        return .list(result)
    }

    static func last(args: [Value], location: Location?) throws -> Value {
        let elements = try args.unwrap1(location).unwrapList(location)
        guard let last = elements.last else { return .nothing }
        return last
    }

    static func take(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let count = try fst.unwrapInteger(location)
        guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

        let elements = try snd.unwrapList(location)
        let take = Array(elements.prefix(count))
        return .list(take)
    }

    static func drop(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let count = try fst.unwrapInteger(location)
        guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

        let elements = try snd.unwrapList(location)
        let drop = Array(elements.dropFirst(count))
        return .list(drop)
    }

    static func length(args: [Value], location: Location?) throws -> Value {
        let elements = try args.unwrap1(location).unwrapList(location)
        return .integer(elements.count)
    }

    static func empty(args: [Value], location: Location?) throws -> Value {
        let n = try length(args: args, location: location).unwrapInteger(location)
        return .boolean(n == 0)
    }

    static func append(args: [Value], location: Location?) throws -> Value {
        try args.mustHaveAtLeast(1, location)
        var result = [Value]()
        for arg in args {
            let list = try arg.unwrapList(location)
            result.append(contentsOf: list)
        }
        return .list(result)
    }

    static func reverse(args: [Value], location: Location?) throws -> Value {
        let list = try args.unwrap1(location).unwrapList(location)
        let reversed = Array(list.reversed())
        return .list(reversed)
    }

    static func nth(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let index = try fst.unwrapInteger(location)
        let list = try snd.unwrapList(location)

        guard index >= 0, index < list.count else {
            throw MyronError(.subscriptOutOfBounds(index, list.count), at: location)
        }

        return list[index]
    }

    static func contains(args: [Value], location: Location?) throws -> Value {
        let (element, snd) = try args.unwrap2(location)
        let list = try snd.unwrapList(location)
        let isContained = try list.contains { value in
            try typeInsensitiveEq(element, value, location: location)
        }

        return .boolean(isContained)
    }

}

// MARK: - Native Lists

extension StandardLists {

    static func cons(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let list = try snd.unwrapList(location)
        let result = [fst] + list
        return .list(result)
    }

    static func list(args: [Value], location: Location?) throws -> Value {
        return .list(args)
    }

}

// TODO: range
// TODO: foldr
// TODO: take-while
// TODO: drop-while
// TODO: zip
// TODO: flatten
// TODO: sort

// MARK: - Helpers

extension StandardLists {

    static func typeInsensitiveEq(
        _ lhs: Value,
        _ rhs: Value,
        location: Location?
    ) throws -> Bool {
        do {
            return try StandardComparison.eq(
                args: [lhs, rhs],
                location: location).unwrapBoolean(location)

        } catch let error as MyronError {
            if case .unexpectedType(_, _) = error.reason {
                return false
            }
            throw error
        }
    }

}
