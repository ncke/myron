import Foundation

// MARK: - Standard Sequence

struct StandardSequence {

    static func head(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.headDispatcher.dispatch(args, location)
    }

    static func tail(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.tailDispatcher.dispatch(args, location)
    }

    static func initial(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.initialDispatcher.dispatch(args, location)
    }

    static func last(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.lastDispatcher.dispatch(args, location)
    }

    static func take(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.takeDispatcher.dispatch(args, location)
    }

    static func drop(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.dropDispatcher.dispatch(args, location)
    }

    static func length(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.lengthDispatcher.dispatch(args, location)
    }

    static func empty(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.emptyDispatcher.dispatch(args, location)
    }

    static func append(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.appendDispatcher.dispatch(args, location)
    }

    static func reverse(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.reverseDispatcher.dispatch(args, location)
    }

    static func nth(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.nthDispatcher.dispatch(args, location)
    }

    static func contains(args: [Value], location: Location?) throws -> Value {
        return try StandardSequence.containsDispatcher.dispatch(args, location)
    }

}

// MARK: - Dispatchers

extension StandardSequence {

    private static let headDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.head),
        Dispatcher.Pattern(0, .string, StandardStrings.head)
    ], sharedArity: .exactly(1))

    private static let tailDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.tail),
        Dispatcher.Pattern(0, .string, StandardStrings.tail)
    ], sharedArity: .exactly(1))

    private static let initialDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.initial),
        Dispatcher.Pattern(0, .string, StandardStrings.initial)
    ], sharedArity: .exactly(1))

    private static let lastDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.last),
        Dispatcher.Pattern(0, .string, StandardStrings.last)
    ], sharedArity: .exactly(1))

    private static let takeDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.take),
        Dispatcher.Pattern(1, .string, StandardStrings.take)
    ], sharedArity: .exactly(2))

    private static let dropDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.drop),
        Dispatcher.Pattern(1, .string, StandardStrings.drop)
    ], sharedArity: .exactly(2))

    private static let lengthDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.length),
        Dispatcher.Pattern(0, .string, StandardStrings.length),
        Dispatcher.Pattern(0, .hashmap, StandardHashmap.length)
    ], sharedArity: .exactly(1))

    private static let emptyDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.empty),
        Dispatcher.Pattern(0, .string, StandardStrings.empty),
        Dispatcher.Pattern(0, .hashmap, StandardHashmap.empty)
    ], sharedArity: .exactly(1))

    private static let appendDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.append),
        Dispatcher.Pattern(0, .string, StandardStrings.append)
    ], sharedArity: .atLeast(1))

    private static let reverseDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.reverse),
        Dispatcher.Pattern(0, .string, StandardStrings.reverse)
    ], sharedArity: .exactly(1))

    private static let nthDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.nth),
        Dispatcher.Pattern(1, .string, StandardStrings.nth)
    ], sharedArity: .exactly(2))

    private static let containsDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.contains),
        Dispatcher.Pattern(1, .string, StandardStrings.contains)
    ], sharedArity: .exactly(2))

}
