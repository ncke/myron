import Foundation

// MARK: - Standard Sequence

struct StandardSequence {

    static func head(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.headDispatcher.dispatch(args, apply, location)
    }

    static func tail(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.tailDispatcher.dispatch(args, apply, location)
    }

    static func initial(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.initialDispatcher.dispatch(args, apply, location)
    }

    static func last(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.lastDispatcher.dispatch(args, apply, location)
    }

    static func take(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.takeDispatcher.dispatch(args, apply, location)
    }

    static func drop(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.dropDispatcher.dispatch(args, apply, location)
    }

    static func length(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.lengthDispatcher.dispatch(args, apply, location)
    }

    static func empty(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.emptyDispatcher.dispatch(args, apply, location)
    }

    static func append(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.appendDispatcher.dispatch(args, apply, location)
    }

    static func reverse(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.reverseDispatcher.dispatch(args, apply, location)
    }

    static func nth(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.nthDispatcher.dispatch(args, apply, location)
    }

    static func contains(args: [Value], apply: Applier, location: Location?) throws -> Value {
        return try StandardSequence.containsDispatcher.dispatch(args, apply, location)
    }

}

// MARK: - Dispatchers

extension StandardSequence {

    private static let headDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.head),
        Dispatcher.Pattern(0, .string, StandardStrings.head)
    ])

    private static let tailDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.tail),
        Dispatcher.Pattern(0, .string, StandardStrings.tail)
    ])

    private static let initialDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.initial),
        Dispatcher.Pattern(0, .string, StandardStrings.initial)
    ])

    private static let lastDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.last),
        Dispatcher.Pattern(0, .string, StandardStrings.last)
    ])

    private static let takeDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.take),
        Dispatcher.Pattern(1, .string, StandardStrings.take)
    ])

    private static let dropDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.drop),
        Dispatcher.Pattern(1, .string, StandardStrings.drop)
    ])

    private static let lengthDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.length),
        Dispatcher.Pattern(0, .string, StandardStrings.length)
    ])

    private static let emptyDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.empty),
        Dispatcher.Pattern(0, .string, StandardStrings.empty)
    ])

    private static let appendDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.append),
        Dispatcher.Pattern(0, .string, StandardStrings.append)
    ])

    private static let reverseDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.reverse),
        Dispatcher.Pattern(0, .string, StandardStrings.reverse)
    ])

    private static let nthDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.nth),
        Dispatcher.Pattern(1, .string, StandardStrings.nth)
    ])

    private static let containsDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardLists.contains),
        Dispatcher.Pattern(1, .string, StandardStrings.contains)
    ])

}



