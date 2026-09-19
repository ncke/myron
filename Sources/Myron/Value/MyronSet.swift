import Foundation

// MARK: - MyronSet

public struct MyronSet {
    private(set) var contents: Set<MyronValue>

    public init() {
        self.contents = []
    }
    
    init(contents: Set<MyronValue>) {
        self.contents = contents
    }
    
    init(array elements: [MyronValueRepresentable]) {
        let contents = elements
            .map { element in element.myronValue }
            .filter { value in value.isStorableKey }

        self.init(contents: Set(contents))
    }

}

// MARK: - Membership Operations

extension MyronSet {

    public func insert(_ member: MyronValue) -> MyronSet {
        guard member.isStorableKey else { return self }
        var result = contents
        result.insert(member)
        return MyronSet(contents: result)
    }
    
    public func remove(_ member: MyronValue) -> MyronSet {
        var result = contents
        result.remove(member)
        return MyronSet(contents: result)
    }
    
    public func contains(_ member: MyronValue) -> Bool {
        return contents.contains(member)
    }
    
    func length() -> Int {
        return contents.count
    }
    
    public var isEmpty: Bool {
        return contents.isEmpty
    }

}

// MARK: - Set Operations

extension MyronSet {
    
    public func union(_ other: MyronSet) -> MyronSet {
        let result = self.contents.union(other)
        return MyronSet(contents: result)
    }
    
    public func intersection(_ other: MyronSet) -> MyronSet {
        let result = self.contents.intersection(other)
        return MyronSet(contents: result)
    }
    
    public func difference(_ other: MyronSet) -> MyronSet {
        let result = self.contents.subtracting(other)
        return MyronSet(contents: result)
    }
    
    public func symmetricDifference(_ other: MyronSet) -> MyronSet {
        let result = self.contents.symmetricDifference(other)
        return MyronSet(contents: result)
    }
    
    public func isSubset(of other: MyronSet) -> Bool {
        return self.contents.isSubset(of: other)
    }
    
    public func isStrictSubset(of other: MyronSet) -> Bool {
        return self.contents.isStrictSubset(of: other)
    }
    
    public func isSuperset(of other: MyronSet) -> Bool {
        return self.contents.isSuperset(of: other)
    }
    
    public func isStrictSuperset(of other: MyronSet) -> Bool {
        return self.contents.isStrictSuperset(of: other)
    }
    
    public func isDisjoint(with other: MyronSet) -> Bool {
        return self.contents.isDisjoint(with: other)
    }
}

// MARK: - Equatable and Hashable

extension MyronSet: Equatable, Hashable {
    
    public static func ==(_ lhs: MyronSet, _ rhs: MyronSet) -> Bool {
        return lhs.contents == rhs.contents
    }
    
}

// MARK: - Description

extension MyronSet: CustomStringConvertible {
    
    public var description: String {
        let description = contents.map { element in "\(element)" }.joined(separator: " ")
        return "#{\(description)}"
    }
    
}
