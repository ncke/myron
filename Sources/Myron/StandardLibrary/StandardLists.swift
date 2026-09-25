import Foundation

// MARK: - StandardLists

struct StandardLists: StandardModule {
    
    static let primitiveDefinitions = [
        
        // MARK: List Sequence
        
        MyronPrimitive(
            primitiveName: "list.head",
            representations: ["head"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapList(location)
                guard let head = elements.first else { return .nothing }
                return head
            }),
        
        MyronPrimitive(
            primitiveName: "list.tail",
            representations: ["tail"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapList(location)
                let tail = Array(elements.dropFirst())
                return .list(tail)
            }),
        
        MyronPrimitive(
            primitiveName: "list.initial",
            representations: ["init"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapList(location)
                let result = Array(elements.dropLast())
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "list.last",
            representations: ["last"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapList(location)
                guard let last = elements.last else { return .nothing }
                return last
            }),
        
        MyronPrimitive(
            primitiveName: "list.take",
            representations: ["take"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let elements = try snd.unwrapList(location)
                let take = Array(elements.prefix(count))
                return .list(take)
            }),
        
        MyronPrimitive(
            primitiveName: "list.drop",
            representations: ["drop"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let elements = try snd.unwrapList(location)
                let drop = Array(elements.dropFirst(count))
                return .list(drop)
            }),
        
        MyronPrimitive(
            primitiveName: "list.length",
            representations: ["length"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapList(location)
                return .integer(elements.count)
            }),
        
        MyronPrimitive(
            primitiveName: "list.empty?",
            representations: ["empty?"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let elements = try args.unwrap1(location).unwrapList(location)
                return .boolean(elements.count == 0)
            }),
        
        MyronPrimitive(
            primitiveName: "list.append",
            representations: ["append"],
            signature: StandardSignature([StandardSignature.list1], allowsVariadic: .homogenous),
            body: { args, location in
                try args.mustHaveAtLeast(1, location)
                var result = [MyronValue]()
                for arg in args {
                    let list = try arg.unwrapList(location)
                    result.append(contentsOf: list)
                }
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "list.reverse",
            representations: ["reverse"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                let list = try args.unwrap1(location).unwrapList(location)
                let reversed = Array(list.reversed())
                return .list(reversed)
            }),
        
        MyronPrimitive(
            primitiveName: "list.nth",
            representations: ["nth"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let index = try fst.unwrapInteger(location)
                let list = try snd.unwrapList(location)

                guard index >= 0, index < list.count else {
                    throw MyronError(.subscriptOutOfBounds(index, list.count), at: location)
                }

                return list[index]
            }),
        
        MyronPrimitive(
            primitiveName: "list.contains?",
            representations: ["contains?"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.list1]),
            body: { args, location in
                let (element, snd) = try args.unwrap2(location)
                let list = try snd.unwrapList(location)
                let isContained = try list.contains { value in
                    try typeInsensitiveEq(element, value, location: location)
                }

                return .boolean(isContained)
            }),
        
        // MARK: Native Lists
    
        MyronPrimitive(
            primitiveName: "list.cons",
            representations: ["cons"],
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let list = try snd.unwrapList(location)
                let result = [fst] + list
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "list.list",
            representations: ["list"],
            body: { args, location in
                return .list(args)
            })
    ]

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
        _ lhs: MyronValue,
        _ rhs: MyronValue,
        location: MyronLocation?
    ) throws -> Bool {
        do {
            return try StandardComparison.compareEq([lhs, rhs], at: location)

        } catch let error as MyronError {
            if case .unexpectedType(_, _) = error.reason {
                return false
            }
            throw error
        }
    }

}
