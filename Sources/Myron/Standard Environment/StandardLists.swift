import Foundation

struct StandardLists {

    static func head(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let elements = try args.unwrap1List(location)
        guard let head = elements.first else { return .nothing }
        return head
    }

    static func tail(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let elements = try args.unwrap1List(location)
        let tail = Array(elements.dropFirst())
        return .list(tail)
    }

    static func last(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let elements = try args.unwrap1List(location)
        guard let last = elements.last else { return .nothing }
        return last
    }

    static func take(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let count = try fst.unwrapInteger(location)
        guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

        let elements = try snd.unwrapList(location)
        let take = Array(elements.prefix(count))
        return .list(take)
    }

    static func drop(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let count = try fst.unwrapInteger(location)
        guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

        let elements = try snd.unwrapList(location)
        let drop = Array(elements.dropFirst(count))
        return .list(drop)
    }

    static func length(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let elements = try args.unwrap1List(location)
        return .integer(elements.count)
    }

    static func empty(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let n = try length(args: args, apply: apply, location: location).unwrapInteger(location)
        return .boolean(n == 0)
    }

}
