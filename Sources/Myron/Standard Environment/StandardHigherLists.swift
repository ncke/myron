import Foundation

struct StandardHigherLists {

    static func map(_ args: [Value], _ apply: Applier) throws -> Value {
        guard
            args.count == 2,
            let function = args.first,
            let list = args.last
        else {
            throw MyronError(reason: .unexpectedArity, location: nil)
        }

        guard case let .list(elements) = list else {
            throw MyronError(reason: .expectedList, location: nil)
        }

        guard case let .procedure(procedure) = function else {
            throw MyronError(reason: .expectedProcedure, location: nil)
        }

        var mappings = [Value]()

        for element in elements {
            mappings.append(try procedure([element]))
        }

        return .list(mappings)
    }

}
