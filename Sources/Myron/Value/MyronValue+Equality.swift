import Foundation

// MARK: - Equality

extension MyronValue {

    func isEqual(_ other: MyronValue) -> Bool {

        func isTriviallyEqual(_ fst: MyronValue, _ snd: MyronValue) -> Bool {
            if let f = fst.asInteger, let s = snd.asInteger { return f == s }
            if let f = fst.asDouble, let s = snd.asDouble { return f == s }
            if let f = fst.asBoolean, let s = snd.asBoolean { return f == s }
            if let f = fst.asString, let s = snd.asString { return f == s }
            if let f = fst.asSymbol, let s = snd.asSymbol { return f == s }
            if case .nothing = fst { return true }
            return false
        }

        var work = [(self, other)]

        while let (fst, snd) = work.popLast() {
            guard fst.kind == snd.kind else { return false }

            switch (fst, snd) {

            case (.list(let f), .list(let s)):
                guard f.count == s.count else { return false }
                work.append(contentsOf: zip(f, s))

            case (.hashmap(let f), .hashmap(let s)):
                guard f.length() == s.length() else { return false }
                for (key, fv) in f.keysValues() {
                    guard let sv = s.get(key: key) else { return false }
                    work.append((fv, sv))
                }

            default:
                guard isTriviallyEqual(fst, snd) else { return false }
            }
        }

        return true
    }

    var isEquatable: Bool {
        return self.flat.first { element in
            !Self.equatableKinds.contains(element.kind)
        } == nil
    }
    
    static let equatableKinds: [MyronValue.Kind] = [
        .boolean, .double, .hashmap, .integer, .list, .nothing, .string, .symbol
    ]

}

// MARK: - Equatable & Hashable

extension MyronValue: Equatable, Hashable {
    
    public static func == (lhs: MyronValue, rhs: MyronValue) -> Bool {
        lhs.isEqual(rhs)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(1234)
    }
    
}
