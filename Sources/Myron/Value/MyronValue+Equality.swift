import Foundation

// MARK: - Equality

extension MyronValue {

    /// Structural equality, iteratively so that deep values cannot overflow
    /// the host stack. Every case answers for itself; a pair of different
    /// cases is never equal, and never coerces.
    func isEqual(_ other: MyronValue) -> Bool {
        var work = [(self, other)]

        while let (fst, snd) = work.popLast() {
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

            case (.boolean(let f), .boolean(let s)): guard f == s else { return false }
            case (.double(let f), .double(let s)): guard f == s else { return false }
            case (.integer(let f), .integer(let s)): guard f == s else { return false }
            case (.string(let f), .string(let s)): guard f == s else { return false }
            case (.symbol(let f), .symbol(let s)): guard f == s else { return false }
            case (.define(let f), .define(let s)): guard f == s else { return false }

            // A callable answers for itself: a primitive by the name it
            // registered under, a procedure by its identity.
            case (.primitive(let f), .primitive(let s)): guard f == s else { return false }
            case (.procedure(let f), .procedure(let s)): guard f == s else { return false }
            case (.higherOrder(let f), .higherOrder(let s)): guard f == s else { return false }
            case (.higherProbe(let f), .higherProbe(let s)): guard f == s else { return false }

            case (.nothing, .nothing): break

            default: return false
            }
        }

        return true
    }

    // All kinds are equatable now. Keeping for now.
    var isEquatable: Bool {
        return self.flat.first { element in
            !Self.equatableKinds.contains(element.kind)
        } == nil
    }
    
    static let equatableKinds: [MyronValue.Kind] = [
        .boolean, .define, .double, .hashmap, .higherOrder, .higherProbe,
        .integer, .list, .nothing, .primitive, .procedure, .string, .symbol
    ]

}

// MARK: - Equatable & Hashable

extension MyronValue: Equatable {
    
    public static func == (lhs: MyronValue, rhs: MyronValue) -> Bool {
        lhs.isEqual(rhs)
    }
    
}
