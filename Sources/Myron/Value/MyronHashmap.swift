import Foundation

// MARK: - MyronHashmap

public struct MyronHashmap {
    private var contents: [Myron.Value.Key: Myron.Value]

    init() {
        contents = [:]
    }

    init(contents: [Myron.Value.Key: Myron.Value]) {
        self.contents = contents
    }

}

// MARK: - Operations

extension MyronHashmap {

    func get(key: Myron.Value.Key) -> Myron.Value? {
        contents[key]
    }
    
    func put(key: Myron.Value.Key, value: Myron.Value) -> MyronHashmap {
        var result = MyronHashmap(contents: contents)
        result.contents[key] = value
        return result
    }

    func remove(key: Myron.Value.Key) -> MyronHashmap {
        if contents[key] == nil { return self }
        var result = MyronHashmap(contents: contents)
        result.contents.removeValue(forKey: key)
        return result
    }

    func hasKey(_ key: Myron.Value.Key) -> Bool {
        return contents[key] != nil
    }

    func keysValues() -> [(Myron.Value.Key, Myron.Value)] {
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

    public var pairs: [(key: Myron.Value.Key, value: Myron.Value)] {
        return keysValues()
    }

    public var keys: [Myron.Value.Key] {
        return Array(contents.keys)
    }

    public var values: [Myron.Value] {
        return Array(contents.values)
    }

    public var count: Int {
        return length()
    }

    public var isEmpty: Bool {
        return empty()
    }

    public subscript(key: Myron.Value.Key) -> Myron.Value? {
        return contents[key]
    }

    public var dictionary: [Myron.Value.Key: Myron.Value] {
        return contents
    }

}
