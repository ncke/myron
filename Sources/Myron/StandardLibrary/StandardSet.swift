import Foundation

struct StandardSet: StandardModule {
 
    // MARK: - Set
    
    static let primitiveDefinitions = [
        
        MyronPrimitive(
            primitiveName: "set.insert",
            representations: ["insert"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.set1]),
            body: { args, location in
                let (element, snd) = try args.unwrap2(location)
                let set = try snd.unwrapSet(location)
                let result = set.insert(element)
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.remove",
            representations: ["remove"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.set1]),
            body: { args, location in
                let (element, snd) = try args.unwrap2(location)
                let set = try snd.unwrapSet(location)
                let result = set.remove(element)
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.contains?",
            representations: ["contains?"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.set1]),
            body: { args, location in
                let (element, snd) = try args.unwrap2(location)
                let set = try snd.unwrapSet(location)
                let result = set.contains(element)
                return .boolean(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.length",
            representations: ["length"],
            signature: StandardSignature([StandardSignature.set1]),
            body: { args, location in
                let set = try args.unwrap1(location).unwrapSet(location)
                let result = set.length()
                return .integer(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.empty?",
            representations: ["empty?"],
            signature: StandardSignature([StandardSignature.set1]),
            body: { args, location in
                let set = try args.unwrap1(location).unwrapSet(location)
                let result = set.isEmpty
                return .boolean(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.set",
            representations: ["set"],
            signature: StandardSignature([StandardSignature.any1], allowsVariadic: .homogenous),
            body: { args, location in
                guard args.count > 0 else { return .set(MyronSet()) }
                let result = MyronSet(array: args)
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.values",
            representations: ["values"],
            signature: StandardSignature([StandardSignature.set1]),
            body: { args, location in
                let set = try args.unwrap1(location).unwrapSet(location)
                return .list(Array(set.contents))
            }),
        
        MyronPrimitive(
            primitiveName: "set.make-set",
            representations: ["make-set"],
            signature: StandardSignature([StandardSignature.listOrMap1]),
            body: { args, location in
                try args.mustHaveAtMost(1, location)
                guard let collection = args.first else {
                    return .set(MyronSet())
                }
                
                if case .list(let elements) = collection {
                    return .set(MyronSet(array: elements))
                }
                
                if case .hashmap(let hm) = collection {
                    var elements = [MyronValue]()
                    for (k, v) in hm.keysValues() {
                        elements.append(.list([k, v]))
                    }
                    return .set(MyronSet(array: elements))
                }
                
                throw MyronError(.unexpectedType(collection.kind, [.list, .hashmap]), at: location)
            }),
        
        MyronPrimitive(
            primitiveName: "set.union",
            representations: ["union"],
            signature: StandardSignature(
                [StandardSignature.set1],
                allowsVariadic: .homogenous),
            body: { args, location in
                try args.mustHaveAtLeast(1, location)
                var result = try args.unwrapFirst(location).unwrapSet(location)
                let tail = args.dropFirst()
                
                for arg in tail {
                    let other = try arg.unwrapSet(location)
                    result = result.union(other)
                }
                
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.intersection",
            representations: ["intersection"],
            signature: StandardSignature(
                [StandardSignature.set1],
                allowsVariadic: .homogenous),
            body: { args, location in
                try args.mustHaveAtLeast(1, location)
                var result = try args.unwrapFirst(location).unwrapSet(location)
                let tail = args.dropFirst()
                
                for arg in tail {
                    let other = try arg.unwrapSet(location)
                    result = result.intersection(other)
                }
                
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.difference",
            representations: ["difference"],
            signature: StandardSignature(
                [StandardSignature.set1],
                allowsVariadic: .homogenous),
            body: { args, location in
                try args.mustHaveAtLeast(1, location)
                var result = try args.unwrapFirst(location).unwrapSet(location)
                let tail = args.dropFirst()
                
                for arg in tail {
                    let other = try arg.unwrapSet(location)
                    result = result.difference(other)
                }
                
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.symmetric-difference",
            representations: ["symmetric-difference"],
            signature: StandardSignature([StandardSignature.set1, StandardSignature.set1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let lhs = try fst.unwrapSet(location)
                let rhs = try snd.unwrapSet(location)
                let result = lhs.symmetricDifference(rhs)
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.is-subset?",
            representations: ["is-subset?"],
            signature: StandardSignature([StandardSignature.set1, StandardSignature.set1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let lhs = try fst.unwrapSet(location)
                let rhs = try snd.unwrapSet(location)
                let result = lhs.isSubset(of: rhs)
                return .boolean(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.is-strict-subset?",
            representations: ["is-strict-subset?"],
            signature: StandardSignature([StandardSignature.set1, StandardSignature.set1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let lhs = try fst.unwrapSet(location)
                let rhs = try snd.unwrapSet(location)
                let result = lhs.isStrictSubset(of: rhs)
                return .boolean(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.is-superset?",
            representations: ["is-superset?"],
            signature: StandardSignature([StandardSignature.set1, StandardSignature.set1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let lhs = try fst.unwrapSet(location)
                let rhs = try snd.unwrapSet(location)
                let result = lhs.isSuperset(of: rhs)
                return .boolean(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.is-strict-superset?",
            representations: ["is-strict-superset?"],
            signature: StandardSignature([StandardSignature.set1, StandardSignature.set1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let lhs = try fst.unwrapSet(location)
                let rhs = try snd.unwrapSet(location)
                let result = lhs.isStrictSuperset(of: rhs)
                return .boolean(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.is-disjoint?",
            representations: ["is-disjoint?"],
            signature: StandardSignature([StandardSignature.set1, StandardSignature.set1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let lhs = try fst.unwrapSet(location)
                let rhs = try snd.unwrapSet(location)
                let result = lhs.isDisjoint(with: rhs)
                return .boolean(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.powerset",
            representations: ["powerset"],
            signature: StandardSignature([StandardSignature.set1]),
            body: { args, location in
                let set = try args.unwrap1(location).unwrapSet(location)
                let result = set.powerset()
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.cartesian-product",
            representations: ["cartesian-product"],
            signature: StandardSignature(
                [StandardSignature.set1, StandardSignature.set1],
                allowsVariadic: .homogenous),
            body: { args, location in
                try args.mustHaveAtLeast(2, location)
                let set = try args.unwrapFirst(location).unwrapSet(location)
                let others = try args.dropFirst().map { other in try other.unwrapSet(location) }
                let result = set.cartesianProduct(with: others)
                return .set(result)
            }),
        
        MyronPrimitive(
            primitiveName: "set.flatten",
            representations: ["flatten"],
            signature: StandardSignature([StandardSignature.set1]),
            body: { args, location in
                var work = Array(try args.unwrap1(location).unwrapSet(location).contents)
                var members = [MyronValue]()
                while let element = work.popLast() {
                    switch element {
                    case .set(let inner): work.append(contentsOf: Array(inner.contents))
                    default: members.append(element)
                    }
                }

                return .set(MyronSet(array: members))
            })
        
    ]
    
}
