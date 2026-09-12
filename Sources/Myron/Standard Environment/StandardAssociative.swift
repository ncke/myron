import Foundation

// MARK: - Standard Associative

struct StandardAssociative {

    static func get(args: [Value], location: Location?) throws -> Value {
        return try StandardAssociative.getDispatcher.dispatch(args, location)
    }

    static func getOr(args: [Value], location: Location?) throws -> Value {
        return try StandardAssociative.getOrDispatcher.dispatch(args, location)
    }

    static func put(args: [Value], location: Location?) throws -> Value {
        return try StandardAssociative.putDispatcher.dispatch(args, location)
    }

    static func remove(args: [Value], location: Location?) throws -> Value {
        return try StandardAssociative.removeDispatcher.dispatch(args, location)
    }

    static func hasKey(args: [Value], location: Location?) throws -> Value {
        return try StandardAssociative.hasKeyDispatcher.dispatch(args, location)
    }

    static func keys(args: [Value], location: Location?) throws -> Value {
        return try StandardAssociative.keysDispatcher.dispatch(args, location)
    }

    static func values(args: [Value], location: Location?) throws -> Value {
        return try StandardAssociative.valuesDispatcher.dispatch(args, location)
    }

}

// MARK: - Dispatchers

extension StandardAssociative {

    private static let getDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardAlist.get),
        Dispatcher.Pattern(1, .hashmap, StandardHashmap.get)
    ], sharedArity: .exactly(2))

    private static let getOrDispatcher = Dispatcher([
        Dispatcher.Pattern(2, .list, StandardAlist.getOr),
        Dispatcher.Pattern(2, .hashmap, StandardHashmap.getOr)
    ], sharedArity: .exactly(3))

    private static let putDispatcher = Dispatcher([
        Dispatcher.Pattern(2, .list, StandardAlist.put),
        Dispatcher.Pattern(2, .hashmap, StandardHashmap.put)
    ], sharedArity: .exactly(3))

    private static let removeDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardAlist.remove),
        Dispatcher.Pattern(1, .hashmap, StandardHashmap.remove)
    ], sharedArity: .exactly(2))

    private static let hasKeyDispatcher = Dispatcher([
        Dispatcher.Pattern(1, .list, StandardAlist.hasKey),
        Dispatcher.Pattern(1, .hashmap, StandardHashmap.hasKey)
    ], sharedArity: .exactly(2))

    private static let keysDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardAlist.keys),
        Dispatcher.Pattern(0, .hashmap, StandardHashmap.keys)
    ], sharedArity: .exactly(1))

    private static let valuesDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardAlist.values),
        Dispatcher.Pattern(0, .hashmap, StandardHashmap.values)
    ], sharedArity: .exactly(1))

}
