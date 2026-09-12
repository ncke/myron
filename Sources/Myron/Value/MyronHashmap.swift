import Foundation

// MARK: - MyronHashmap

public struct MyronHashmap {
    private var contents: [MyronKey: MyronValue]

    init() {
        contents = [:]
    }

    init(contents: [MyronKey: MyronValue]) {
        self.contents = contents
    }

}

// MARK: - Operations

extension MyronHashmap {

    func get(key: MyronKey) -> MyronValue? {
        contents[key]
    }
    
    func put(key: MyronKey, value: MyronValue) -> MyronHashmap {
        var result = MyronHashmap(contents: contents)
        result.contents[key] = value
        return result
    }

    func remove(key: MyronKey) -> MyronHashmap {
        if contents[key] == nil { return self }
        var result = MyronHashmap(contents: contents)
        result.contents.removeValue(forKey: key)
        return result
    }

    func hasKey(_ key: MyronKey) -> Bool {
        return contents[key] != nil
    }

    func keysValues() -> [(MyronKey, MyronValue)] {
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

    public var pairs: [(key: MyronKey, value: MyronValue)] {
        return keysValues()
    }

    public var keys: [MyronKey] {
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

    public subscript(key: MyronKey) -> MyronValue? {
        return contents[key]
    }

    public var dictionary: [MyronKey: MyronValue] {
        return contents
    }

}
