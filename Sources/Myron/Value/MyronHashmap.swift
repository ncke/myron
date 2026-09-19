import Foundation

// MARK: - MyronHashmap

public struct MyronHashmap {
    private var contents: [MyronValue: MyronValue]

    init() {
        contents = [:]
    }

    init(contents: [MyronValue: MyronValue]) {
        self.contents = contents
    }

}

// MARK: - Operations

extension MyronHashmap {

    func get(key: MyronValue) -> MyronValue? {
        contents[key]
    }
    
    func put(key: MyronValue, value: MyronValue) -> MyronHashmap {
        guard key.isStorableKey else { return self }
        var result = MyronHashmap(contents: contents)
        result.contents[key] = value
        return result
    }

    func remove(key: MyronValue) -> MyronHashmap {
        if contents[key] == nil { return self }
        var result = MyronHashmap(contents: contents)
        result.contents.removeValue(forKey: key)
        return result
    }

    func hasKey(_ key: MyronValue) -> Bool {
        return contents[key] != nil
    }

    func keysValues() -> [(MyronValue, MyronValue)] {
        return contents.map { element in (element.key, element.value) }
    }

    func length() -> Int {
        return contents.count
    }

    func empty() -> Bool {
        return contents.isEmpty
    }

}

// MARK: - Description

extension MyronHashmap: CustomStringConvertible {

    public var description: String {
        let description = contents.map { (key, value) in
            "(\(key) \(value))"
        }.joined(separator: " ")

        return "#(\(description))"
    }

}

// MARK: - Swift Accessors

extension MyronHashmap {

    public var pairs: [(key: MyronValue, value: MyronValue)] {
        return keysValues()
    }

    public var keys: [MyronValue] {
        return Array(contents.keys)
    }

    public var values: [MyronValue] {
        return Array(contents.values)
    }

    public var count: Int {
        return length()
    }

    public var isEmpty: Bool {
        return empty()
    }

    public subscript(key: MyronValue) -> MyronValue? {
        return contents[key]
    }

    public var dictionary: [MyronValue: MyronValue] {
        return contents
    }

}

// MARK: - Equatable & Hashable

extension MyronHashmap: Equatable, Hashable {
    
    public static func == (lhs: MyronHashmap, rhs: MyronHashmap) -> Bool {
        MyronValue.hashmap(lhs).isEqual(MyronValue.hashmap(rhs))
    }
    
    public func hash(into hasher: inout Hasher) {
        var accumulated = 0

        for (key, value) in keysValues() {
            var entryHasher = Hasher()
            entryHasher.combine(key)
            entryHasher.combine(value)
            accumulated ^= entryHasher.finalize()
        }

        hasher.combine(length())
        hasher.combine(accumulated)
    }
    
}
