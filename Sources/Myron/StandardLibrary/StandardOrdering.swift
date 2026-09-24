import Foundation

// MARK: - Standard Ordering

struct StandardOrdering: StandardModule {
    
    static let primitiveDefinitions = [
        
        // MARK: Sort
        
        MyronPrimitive(
            primitiveName: "ordering.sort",
            representations: ["sort"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapElements(location)
                let comparator = makeComparator(
                    body: StandardComparison.compareLt,
                    location: location)
                let sorted = try elements.sorted(by: comparator)
                return .list(sorted)
            }),
        
        MyronPrimitive(
            primitiveName: "ordering.sort-descending",
            representations: ["sort-descending"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapElements(location)
                let comparator = makeComparator(
                    body: StandardComparison.compareGt,
                    location: location)
                let sorted = try elements.sorted(by: comparator)
                return .list(sorted)
            })
    ]
}

// MARK: - Helpers

extension StandardOrdering {
    
    private static func makeComparator(
        body: @escaping ([MyronValue], MyronLocation?) throws -> Bool,
        location: MyronLocation?
    ) -> (MyronValue, MyronValue) throws -> Bool {
        let comparator: (MyronValue, MyronValue) throws -> Bool = {
            lhs, rhs in return try body([lhs, rhs], location)
        }
        
        return comparator
    }
    
}
