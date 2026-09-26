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
            primitiveName: "list.take-last",
            representations: ["take-last"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let elements = try snd.unwrapList(location)
                let take = Array(elements.suffix(count))
                return .list(take)
            }),
        
        MyronPrimitive(
            primitiveName: "list.drop-last",
            representations: ["drop-last"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let elements = try snd.unwrapList(location)
                let prefixCount = max(0, elements.count - count)
                let drop = Array(elements.prefix(prefixCount))
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

        MyronPrimitive(
            primitiveName: "list.range",
            representations: ["range"],
            signature: StandardSignature([
                StandardSignature.int1,
                StandardSignature.int1,
                StandardSignature.list1]),
            body: { args, location in
                let (fst, snd, thd) = try args.unwrap3(location)
                let start = try fst.unwrapInteger(location)
                let finish = try snd.unwrapInteger(location)
                let list = try thd.unwrapList(location)

                guard start >= 0, finish >= 0 else {
                    throw MyronError(.cannotBeNegative, at: location)
                }

                guard start < list.endIndex, finish > start else { return .list([]) }

                let slice = list[start..<min(finish, list.endIndex)]
                return .list(Array(slice))
            }),

        MyronPrimitive(
            primitiveName: "list.range-len",
            representations: ["range-len"],
            signature: StandardSignature([
                StandardSignature.int1,
                StandardSignature.int1,
                StandardSignature.list1]),
            body: { args, location in
                let (fst, snd, thd) = try args.unwrap3(location)
                let start = try fst.unwrapInteger(location)
                let len = try snd.unwrapInteger(location)
                let list = try thd.unwrapList(location)

                guard start >= 0, len >= 0 else {
                    throw MyronError(.cannotBeNegative, at: location)
                }

                let (sum, isOverflow) = start.addingReportingOverflow(len)
                let finish = isOverflow ? Int.max : sum

                guard start < list.endIndex, finish > start else { return .list([]) }

                let slice = list[start..<min(finish, list.endIndex)]
                return .list(Array(slice))
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
            }),
        
        MyronPrimitive(
            primitiveName: "list.zip",
            representations: ["zip"],
            signature: StandardSignature([StandardSignature.list1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let (list1, list2) = (try fst.unwrapList(location), try snd.unwrapList(location))
                var result = [MyronValue]()
                var iterator1 = list1.makeIterator()
                var iterator2 = list2.makeIterator()
                
                while true {
                    guard let e1 = iterator1.next(), let e2 = iterator2.next() else { break }
                    result.append(.list([e1, e2]))
                }
                
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "list.zip-all",
            representations: ["zip-all"],
            signature: StandardSignature([StandardSignature.list1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let (list1, list2) = (try fst.unwrapList(location), try snd.unwrapList(location))
                var result = [MyronValue]()
                var iterator1 = list1.makeIterator()
                var iterator2 = list2.makeIterator()
                
                while true {
                    let (e1, e2) = (iterator1.next(), iterator2.next())
                    if e1 == nil && e2 == nil { break }
                    result.append(.list([e1 ?? .nothing, e2 ?? .nothing]))
                }
                
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "list.flatten",
            representations: ["flatten"],
            signature: StandardSignature([StandardSignature.list1]),
            body: { args, location in
                var result = [MyronValue]()
                var stack = [(Int, [MyronValue])]()
                var work = try args.unwrap1(location).unwrapList(location)
                var cursor = work.startIndex
                
                func next() -> MyronValue? {
                    if cursor < work.endIndex { defer { cursor += 1 }; return work[cursor] }
                    
                    while let popped = stack.popLast() {
                        (cursor, work) = popped
                        if cursor < work.endIndex { defer { cursor += 1 }; return work[cursor] }
                    }
                    
                    return nil
                }
                
                func push(then elements: [MyronValue]) {
                    guard elements.count > 0 else { return }
                    stack.append((cursor, work))
                    work = elements
                    cursor = work.startIndex
                }
                
                while let value = next() {
                    switch value {
                    case .list(let elements): push(then: elements)
                    default: result.append(value)
                    }
                }
                
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "list.integers",
            representations: ["integers"],
            signature: StandardSignature([StandardSignature.int1]),
            body: { args, location in
                let limit = try args.unwrap1(location).unwrapInteger(location)
                guard limit >= 1 else { return .list([]) }
                
                var result = [MyronValue]()
                var counter = 0
                while counter != limit {
                    result.append(.integer(counter))
                    counter += 1
                }
                
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "list.integers-between",
            representations: ["integers-between"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.int1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let start = try fst.unwrapInteger(location)
                let finish = try snd.unwrapInteger(location)
                guard finish > start else { return .list([]) }
                
                var result = [MyronValue]()
                var counter = start
                while counter != finish {
                    result.append(.integer(counter))
                    counter += 1
                }
                
                return .list(result)
            }),
    ]

}

// TODO: take-while
// TODO: drop-while

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
