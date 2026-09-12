import Foundation

// MARK: - MyronHashmap

public struct MyronHashmap {
    private var contents: [Value.Key: Value]

    init() {
        contents = [:]
    }

    init(contents: [Value.Key: Value]) {
        self.contents = contents
    }

}

// MARK: - Operations

extension MyronHashmap {

    func get(key: Value.Key) -> Value? {
        contents[key]
    }
    
    func put(key: Value.Key, value: Value) -> MyronHashmap {
        var result = MyronHashmap(contents: contents)
        result.contents[key] = value
        return result
    }

    func remove(key: Value.Key) -> MyronHashmap {
        if contents[key] == nil { return self }
        var result = MyronHashmap(contents: contents)
        result.contents.removeValue(forKey: key)
        return result
    }

    func hasKey(_ key: Value.Key) -> Bool {
        return contents[key] != nil
    }

    func keys() -> [Value.Key] {
        return Array(contents.keys)
    }

    func values() -> [Value] {
        return Array(contents.values)
    }

    func keysValues() -> [(Value.Key, Value)] {
        return Array(contents.map { element in (element.key, element.value) })
    }

    func length() -> Int {
        return contents.count
    }

    func isEmpty() -> Bool {
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
