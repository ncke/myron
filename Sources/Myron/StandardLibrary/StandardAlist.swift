import Foundation

// MARK: - StandardAlist

struct StandardAlist: StandardModule {
    
    static let primitiveDefinitions = [
        
        // MARK: Associative
        
        MyronPrimitive(
            primitiveName: "alist.get",
            representations: ["get"],
            signature: StandardSignature([StandardSignature.oneAny, StandardSignature.oneList]),
            body: { args, location in
                let (key, snd) = try args.unwrap2(location)
                let list = try snd.unwrapList(location)
                let result = try findKey(key, in: list, validating: false, at: location)
                
                guard let (_, value) = result else { return .nothing }
                return value
            }),
        
        MyronPrimitive(
            primitiveName: "alist.get-or",
            representations: ["get-or"],
            signature: StandardSignature([
                StandardSignature.oneAny,
                StandardSignature.oneAny,
                StandardSignature.oneList]),
            body: { args, location in
                let (def, key, snd) = try args.unwrap3(location)
                let list = try snd.unwrapList(location)
                let result = try findKey(key, in: list, validating: false, at: location)
                
                guard let (_, value) = result else { return def }
                return value
            }),
        
        MyronPrimitive(
            primitiveName: "alist.put",
            representations: ["put"],
            signature: StandardSignature([
                StandardSignature.oneAny,
                StandardSignature.oneAny,
                StandardSignature.oneList]),
            body: { args, location in
                let (key, value, thd) = try args.unwrap3(location)
                if case .nothing = value {
                    return try removingKey(key, from: thd, at: location)
                }
                
                var list = try thd.unwrapList(location)
                guard key.isStorableKey else { return .list(list) }
                
                let pair = MyronValue.list([key, value])
                let found = try findKey(key, in: list, validating: true, at: location)
                
                if let (idx, _) = found { list[idx] = pair } else { list.append(pair) }
                return .list(list)
            }),
        
        MyronPrimitive(
            primitiveName: "alist.remove",
            representations: ["remove"],
            signature: StandardSignature([StandardSignature.oneAny, StandardSignature.oneList]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                return try removingKey(fst, from: snd, at: location)
            }),
        
        MyronPrimitive(
            primitiveName: "alist.has-key?",
            representations: ["has-key?"],
            signature: StandardSignature([StandardSignature.oneAny, StandardSignature.oneList]),
            body: { args, location in
                let (key, snd) = try args.unwrap2(location)
                let list = try snd.unwrapList(location)
                let result = try findKey(key, in: list, validating: false, at: location)
                
                return .boolean(result != nil)
            }),
        
        MyronPrimitive(
            primitiveName: "alist.keys",
            representations: ["keys"],
            signature: StandardSignature([StandardSignature.oneList]),
            body: { args, location in
                let pairs = try unwrapPairs(args, at: location)
                return .list(pairs.map { (key, _) in key })
            }),
        
        MyronPrimitive(
            primitiveName: "alist.values",
            representations: ["values"],
            signature: StandardSignature([StandardSignature.oneList]),
            body: { args, location in
                let pairs = try unwrapPairs(args, at: location)
                return .list(pairs.map { (_, value) in value })
            }),
        
        // MARK: Native Alist
        
        MyronPrimitive(
            primitiveName: "alist.key-index",
            representations: ["key-index"],
            body: { args, location in
                let (key, snd) = try args.unwrap2(location)
                let list = try snd.unwrapList(location)
                let result = try findKey(key, in: list, validating: false, at: location)
                
                guard let (idx, _) = result else { return .nothing }
                return .integer(idx)
            })
    
    ]

}

// MARK: - Helpers

extension StandardAlist {
    
    private static func removingKey(
        _ key: MyronValue,
        from listValue: MyronValue,
        at location: MyronLocation?
    ) throws -> MyronValue {
        var list = try listValue.unwrapList(location)
        let found = try findKey(key, in: list, validating: false, at: location)
        
        guard let (idx, _) = found else { return listValue }
        
        list.remove(at: idx)
        return .list(list)
    }
    
    private static func unwrapPairs(
        _ args: [MyronValue],
        at location: MyronLocation?
    ) throws -> [(MyronValue, MyronValue)] {
        let list = try args.unwrap1(location).unwrapList(location)
        var pairs = [(MyronValue, MyronValue)]()
        
        for (idx, element) in list.enumerated() {
            guard case .list(let pair) = element, pair.count == 2 else {
                throw MyronError(.malformedAlist(idx), at: location)
            }
            
            if case .nothing = pair[1] {
                throw MyronError(.malformedAlist(idx), at: location)
            }
            
            pairs.append((pair[0], pair[1]))
        }
        
        return pairs
    }

    private static func findKey(
        _ key: MyronValue,
        in list: [MyronValue],
        validating: Bool,
        at location: MyronLocation?
    ) throws -> (Int, MyronValue)? {
        var matches = [(Int, MyronValue)]()

        for (idx, element) in list.enumerated() {
            guard case .list(let pair) = element, pair.count == 2 else {
                throw MyronError(.malformedAlist(idx), at: location)
            }

            if case .nothing = pair[1] {
                throw MyronError(.malformedAlist(idx), at: location)
            }

            if pair[0] == key {
                let result = (idx, pair[1])
                if !validating { return result }
                matches.append(result)
            }
        }

        guard matches.count <= 1 else {
            let indices = matches.map { (idx, _) in idx }
            throw MyronError(.duplicateKeys(indices), at: location)
        }

        guard let firstMatch = matches.first else { return nil }
        return firstMatch
    }

}
