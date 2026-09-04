import Foundation

struct StandardSequence {

    static func length(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        return try StandardSequence.lengthDispatcher.dispatch(
            args: args,
            apply: apply,
            location: location)
    }

}

extension StandardSequence {

    private static let lengthDispatcher = Dispatcher([
        Dispatcher.Pattern(0, .list, StandardLists.length),
        Dispatcher.Pattern(0, .string, StandardStrings.length)
    ])


}



