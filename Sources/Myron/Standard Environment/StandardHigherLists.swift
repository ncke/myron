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

    static func filter(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (function, list) = try args.unwrap2(location)
        let elements = try list.unwrapList(location)

        var mappings = [Value]()
        for element in elements {
            let included = try apply(function, [element], location).unwrapBoolean(location)
            if included { mappings.append(element) }
        }

        return .list(mappings)
    }

    static func reduce(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let (function, initial, list) = try args.unwrap3(location)
        var accumulator = initial
        let elements = try list.unwrapList(location)
        
        for element in elements {
            accumulator = try apply(function, [accumulator, element], location)
        }

        return accumulator
    }

}
