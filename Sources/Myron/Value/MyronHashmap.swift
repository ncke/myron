import Foundation

// MARK: - MyronHashmap

public struct MyronHashmap {
    private var contents: [MyronValue.Key: MyronValue]

    init() {
        contents = [:]
    }

    init(contents: [MyronValue.Key: MyronValue]) {
        self.contents = contents
    }

}

// MARK: - Operations

extension MyronHashmap {

    func get(key: MyronValue.Key) -> MyronValue? {
        contents[key]
    }
    
    func put(key: MyronValue.Key, value: MyronValue) -> MyronHashmap {
        var result = MyronHashmap(contents: contents)
        result.contents[key] = value
        return result
    }

    func remove(key: MyronValue.Key) -> MyronHashmap {
        if contents[key] == nil { return self }
        var result = MyronHashmap(contents: contents)
        result.contents.removeValue(forKey: key)
        return result
    }

    func hasKey(_ key: MyronValue.Key) -> Bool {
        return contents[key] != nil
    }

    func keysValues() -> [(MyronValue.Key, MyronValue)] {
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

    public var pairs: [(key: MyronValue.Key, value: MyronValue)] {
        return keysValues()
    }

    public var keys: [MyronValue.Key] {
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

    public subscript(key: MyronValue.Key) -> MyronValue? {
        return contents[key]
    }

    public var dictionary: [MyronValue.Key: MyronValue] {
        return contents
    }

}
