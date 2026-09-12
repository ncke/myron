import Foundation

// MARK: - StandardHashmap

// MARK: - Associative

struct StandardHashmap {

    static func get(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (fst, snd) = try args.unwrap2(location)
        let key = try MyronKey(fst, at: location)
        let hashmap = try snd.unwrapHashmap(location)

        guard let result = hashmap.get(key: key) else { return .nothing }
        return result
    }

    static func getOr(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (def, fst, snd) = try args.unwrap3(location)
        let key = try MyronKey(fst, at: location)
        let hashmap = try snd.unwrapHashmap(location)

        guard let result = hashmap.get(key: key) else { return def }
        return result
    }

    static func put(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (fst, value, thd) = try args.unwrap3(location)
        if case .nothing = value {
            return try remove(args: [fst, thd], location: location)
        }

        let key = try MyronKey(fst, at: location)
        let hashmap = try thd.unwrapHashmap(location)

        return .hashmap(hashmap.put(key: key, value: value))
    }

    static func remove(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (fst, snd) = try args.unwrap2(location)
        let key = try MyronKey(fst, at: location)
        let hashmap = try snd.unwrapHashmap(location)

        return .hashmap(hashmap.remove(key: key))
    }

    static func hasKey(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let (fst, snd) = try args.unwrap2(location)
        let key = try MyronKey(fst, at: location)
        let hashmap = try snd.unwrapHashmap(location)

        return .boolean(hashmap.hasKey(key))
    }

    static func keys(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let hashmap = try args.unwrap1(location).unwrapHashmap(location)
        return .list(hashmap.keys.map { key in key.value })
    }

    static func values(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let hashmap = try args.unwrap1(location).unwrapHashmap(location)
        return .list(hashmap.values)
    }

}

// MARK: - Partial Sequence

extension StandardHashmap {

    static func length(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let hashmap = try args.unwrap1(location).unwrapHashmap(location)
        return .integer(hashmap.length())
    }

    static func empty(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let hashmap = try args.unwrap1(location).unwrapHashmap(location)
        return .boolean(hashmap.empty())
    }

}

// MARK: - Native Hashmap

extension StandardHashmap {

    static func makeHashmap(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        try args.mustHaveAtMost(1, location)
        guard let alist = try args.first?.unwrapList(location) else {
            return .hashmap(MyronHashmap())
        }

        var contents = [MyronKey: MyronValue]()
        var seen = [MyronKey: Int]()

        for (idx, element) in alist.enumerated() {
            guard case .list(let pair) = element, pair.count == 2 else {
                throw MyronError(.malformedAlist(idx), at: location)
            }

            if case .nothing = pair[1] {
                throw MyronError(.malformedAlist(idx), at: location)
            }

            let key = try MyronKey(pair[0], at: location)

            if let dupIdx = seen[key] {
                throw MyronError(.duplicateKeys([dupIdx, idx]), at: location)
            }

            contents[key] = pair[1]
            seen[key] = idx
        }

        return .hashmap(MyronHashmap(contents: contents))
    }

    static func keysValues(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        let hashmap = try args.unwrap1(location).unwrapHashmap(location)
        let kvs = hashmap.keysValues()
        let pairs = kvs.map { (k, v) in MyronValue.list([k.value, v])  }

        return .list(pairs)
    }

}
