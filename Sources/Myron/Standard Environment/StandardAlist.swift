import Foundation

// MARK: - StandardAlist

struct StandardAlist {

    private static func findKey(
        _ key: Value.Key,
        in list: [Value],
        validating: Bool,
        at location: Location?
    ) throws -> (Int, Value)? {
        var matches = [(Int, Value)]()

        for (idx, element) in list.enumerated() {
            guard case .list(let pair) = element, pair.count == 2 else {
                throw MyronError(.malformedAlist(idx), at: location)
            }

            let pairKey = try Value.Key.fromValue(pair[0], at: location)
            if pairKey == key {
                let result = (idx, pair[1])
                if !validating { return result }
                matches.append(result)
            }
        }

        guard matches.count <= 1 else {
            let indices = matches.map { (idx, _) in idx }
            throw MyronError(.duplicateKeys(indices), at: location)
        }

        if let firstMatch = matches.first { return firstMatch }
        return nil
    }

    static func get(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let key = try Value.Key.fromValue(fst, at: location)
        let list = try snd.unwrapList(location)
        let result = try findKey(key, in: list, validating: false, at: location)

        if let (_, value) = result { return value }
        return .nothing
    }

    static func getOr(args: [Value], location: Location?) throws -> Value {
        let (def, fst, snd) = try args.unwrap3(location)
        let key = try Value.Key.fromValue(fst, at: location)
        let list = try snd.unwrapList(location)
        let result = try findKey(key, in: list, validating: false, at: location)

        if let (_, value) = result { return value }
        return def
    }

    static func put(args: [Value], location: Location?) throws -> Value {
        let (fst, value, thd) = try args.unwrap3(location)
        if case .nothing = value {
            return try remove(args: [fst, thd], location: location)
        }

        let key = try Value.Key.fromValue(fst, at: location)
        let pair = Value.list([fst, value])
        var list = try thd.unwrapList(location)
        let found = try findKey(key, in: list, validating: true, at: location)

        if let (idx, _) = found { list[idx] = pair } else { list.append(pair) }

        return .list(list)
    }

    static func remove(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let key = try Value.Key.fromValue(fst, at: location)
        var list = try snd.unwrapList(location)
        let found = try findKey(key, in: list, validating: false, at: location)

        if let (idx, _) = found {
            list.remove(at: idx)
            return .list(list)
        }

        return snd
    }

    static func hasKey(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let key = try Value.Key.fromValue(fst, at: location)
        let list = try snd.unwrapList(location)
        let result = try findKey(key, in: list, validating: false, at: location)

        return .boolean(result != nil)
    }

    static func keys(args: [Value], location: Location?) throws -> Value {
        let fst = try args.unwrap1(location)
        let list = try fst.unwrapList(location)
        var ks = [Value]()
        for (idx, element) in list.enumerated() {
            guard case .list(let pair) = element, pair.count == 2 else {
                throw MyronError(.malformedAlist(idx), at: location)
            }

            let key = pair[0]
            _ = try Value.Key.fromValue(key, at: location)
            ks.append(key)
        }

        return .list(ks)
    }

    static func values(args: [Value], location: Location?) throws -> Value {
        let fst = try args.unwrap1(location)
        let list = try fst.unwrapList(location)
        var vs = [Value]()
        for (idx, element) in list.enumerated() {
            guard case .list(let pair) = element, pair.count == 2 else {
                throw MyronError(.malformedAlist(idx), at: location)
            }

            _ = try Value.Key.fromValue(pair[0], at: location)
            vs.append(pair[1])
        }

        return .list(vs)
    }

    static func keyIndex(args: [Value], location: Location?) throws -> Value {
        let (fst, snd) = try args.unwrap2(location)
        let key = try Value.Key.fromValue(fst, at: location)
        let list = try snd.unwrapList(location)
        let result = try findKey(key, in: list, validating: false, at: location)
        
        if let (idx, _) = result {
            return .integer(idx)
        }

        return .nothing
    }

}
