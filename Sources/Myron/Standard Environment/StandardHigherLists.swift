import Foundation

// MARK: - Higher-Order Lists

struct StandardHigherLists {

    static func map(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (function, list) = try args.unwrap2(location)
        let elements = try list.unwrapList(location)

        var mappings = [Value]()
        for element in elements {
            let mapping = try apply(function, [element], location)
            mappings.append(mapping)
        }

        return .list(mappings)
    }

}
