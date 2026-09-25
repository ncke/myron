import Foundation

// MARK: - MyronRecord

public struct MyronRecord {
    public let type: MyronRecordType
    let contents: [MyronValue]
    
    init(type: MyronRecordType, contents: [MyronValue]) {
        self.type = type
        self.contents = contents
    }
    
    init(
        type: MyronRecordType,
        fields: [String: MyronValue],
        location: MyronLocation?
    ) throws {
        var contents = [MyronValue](repeating: .nothing, count: type.fields.count)
        for (field, value) in fields {
            guard let idx = type.positions[field] else {
                throw MyronError(.unexpectedField(field, type.name, type.fields), at: location)
            }
            
            contents[idx] = value
        }
        
        self.type = type
        self.contents = contents
    }
    
}

// MARK: - Operations

extension MyronRecord {

    func get(field: String, location: MyronLocation?) throws -> MyronValue {
        return contents[try indexForField(field, location: location)]
    }
    
    func put(field: String, value: MyronValue, location: MyronLocation?) throws -> MyronRecord {
        var next = contents
        next[try indexForField(field, location: location)] = value
        return MyronRecord(type: self.type, contents: next)
    }

    func keysValues() -> [(MyronValue, MyronValue)] {
        return zip(type.fields, contents).map { (field, value) in (.symbol(field), value) }
    }

}

// MARK: - Swift Accessors

extension MyronRecord {
    
    public var typeName: String {
        return type.name
    }
    
    public var fields: [String] {
        return type.fields
    }
    
    public func hasField(_ field: String) -> Bool {
        return type.hasField(field)
    }

    public var pairs: [(key: MyronValue, value: MyronValue)] {
        return keysValues()
    }

    public var values: [MyronValue] {
        return contents
    }

    public subscript(field: String) -> MyronValue? {
        guard let idx = type.positions[field] else { return nil }
        return contents[idx]
    }

    public var dictionary: [MyronValue: MyronValue] {
        return Dictionary(uniqueKeysWithValues: keysValues())
    }

}

// MARK: - Field Handling

extension MyronRecord {
    
    private func indexForField(_ field: String, location: MyronLocation?) throws -> Int {
        guard let idx = type.positions[field] else {
            throw MyronError(.unexpectedField(field, type.name, type.fields), at: location)
        }
        
        return idx
    }
        
}

// MARK: - Description

extension MyronRecord: CustomStringConvertible {
    
    public var description: String {
        let describe = zip(type.fields, contents)
            .map { (field, value) in "\(field): \(value)" }
            .joined(separator: " ")
        return "<record: \(type.name) (\(describe))>"
    }
    
}

// MARK: - Equatable & Hashable

extension MyronRecord: Equatable, Hashable {}
