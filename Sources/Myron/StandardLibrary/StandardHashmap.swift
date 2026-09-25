import Foundation

// MARK: - StandardHashmap

struct StandardHashmap: StandardModule {
    
    static let primitiveDefinitions = [
        
        // MARK: Associative
        
        MyronPrimitive(
            primitiveName: "hashmap.get",
            representations: ["get"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.map1]),
            body: { args, location in
                let (key, snd) = try args.unwrap2(location)
                let hashmap = try snd.unwrapHashmap(location)
                
                guard let result = hashmap.get(key: key) else { return .nothing }
                return result
            }),
        
        MyronPrimitive(
            primitiveName: "hashmap.get-or",
            representations: ["get-or"],
            signature: StandardSignature([
                StandardSignature.any1,
                StandardSignature.any1,
                StandardSignature.map1]),
            body: { args, location in
                let (def, key, snd) = try args.unwrap3(location)
                let hashmap = try snd.unwrapHashmap(location)
                
                guard let result = hashmap.get(key: key) else { return def }
                return result
            }),
        
        MyronPrimitive(
            primitiveName: "hashmap.put",
            representations: ["put"],
            signature: StandardSignature([
                StandardSignature.any1,
                StandardSignature.any1,
                StandardSignature.map1]),
            body: { args, location in
                let (key, value, thd) = try args.unwrap3(location)
                if case .nothing = value {
                    return try removingKey(key, from: thd, at: location)
                }
                
                let hashmap = try thd.unwrapHashmap(location)
                return .hashmap(hashmap.put(key: key, value: value))
            }),
        
        MyronPrimitive(
            primitiveName: "hashmap.remove",
            representations: ["remove"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.map1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                return try removingKey(fst, from: snd, at: location)
            }),
        
        MyronPrimitive(
            primitiveName: "hashmap.has-key?",
            representations: ["has-key?"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.map1]),
            body: { args, location in
                let (key, snd) = try args.unwrap2(location)
                let hashmap = try snd.unwrapHashmap(location)
                
                return .boolean(hashmap.hasKey(key))
            }),
        
        MyronPrimitive(
            primitiveName: "hashmap.keys",
            representations: ["keys"],
            signature: StandardSignature([StandardSignature.map1]),
            body: { args, location in
                let hashmap = try args.unwrap1(location).unwrapHashmap(location)
                return .list(hashmap.keys)
            }),
        
        MyronPrimitive(
            primitiveName: "hashmap.values",
            representations: ["values"],
            signature: StandardSignature([StandardSignature.map1]),
            body: { args, location in
                let hashmap = try args.unwrap1(location).unwrapHashmap(location)
                return .list(hashmap.values)
            }),
        
        // MARK: Partial Sequence
        
        MyronPrimitive(
            primitiveName: "hashmap.length",
            representations: ["length"],
            signature: StandardSignature([StandardSignature.map1]),
            body: { args, location in
                let hashmap = try args.unwrap1(location).unwrapHashmap(location)
                return .integer(hashmap.length())
            }),
        
        MyronPrimitive(
            primitiveName: "hashmap.empty?",
            representations: ["empty?"],
            signature: StandardSignature([StandardSignature.map1]),
            body: { args, location in
                let hashmap = try args.unwrap1(location).unwrapHashmap(location)
                return .boolean(hashmap.empty())
            }),
        
        // MARK: Native Hashmap
        
        MyronPrimitive(
            primitiveName: "hashmap.make-hashmap",
            representations: ["make-hashmap"],
            signature: StandardSignature([StandardSignature.listOrRec1]),
            body: { args, location in
                try args.mustHaveAtMost(1, location)
                
                guard let fst = args.first else {
                    return .hashmap(MyronHashmap())
                }
                
                var contents = [MyronValue: MyronValue]()
                
                if let record = fst.asRecord {
                    for (key, value) in record.keysValues() where !value.isNothing {
                        contents[key] = value
                    }
                    
                } else if let alist = fst.asList {
                    var seen = [MyronValue: Int]()
                    for (idx, element) in alist.enumerated() {
                        guard case .list(let pair) = element, pair.count == 2 else {
                            throw MyronError(.malformedAlist(idx), at: location)
                        }
                        
                        if case .nothing = pair[1] {
                            throw MyronError(.malformedAlist(idx), at: location)
                        }
                        
                        let key = pair[0]
                        guard key.isStorableKey else { continue }
                        
                        if let dupIdx = seen[key] {
                            throw MyronError(.duplicateKeys([dupIdx, idx]), at: location)
                        }
                        
                        contents[key] = pair[1]
                        seen[key] = idx
                    }
                    
                } else {
                    throw MyronError(.unexpectedType(fst.kind, [.list, .record]), at: location)
                }
                
                return .hashmap(MyronHashmap(contents: contents))
            }),

        MyronPrimitive(
            primitiveName: "hashmap.keys-values",
            representations: ["keys-values"],
            signature: StandardSignature([StandardSignature.map1]),
            body: { args, location in
                let hashmap = try args.unwrap1(location).unwrapHashmap(location)
                let kvs = hashmap.keysValues()
                let pairs = kvs.map { (k, v) in MyronValue.list([k, v])  }
                
                return .list(pairs)
            })
    ]

}

// MARK: - Helpers

extension StandardHashmap {
    
    private static func removingKey(
        _ key: MyronValue,
        from hashmapValue: MyronValue,
        at location: MyronLocation?
    ) throws -> MyronValue {
        let hashmap = try hashmapValue.unwrapHashmap(location)
        return .hashmap(hashmap.remove(key: key))
    }
    
}
