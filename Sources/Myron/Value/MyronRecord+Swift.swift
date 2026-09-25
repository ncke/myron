import Foundation

// MARK: - Initialisers

extension MyronRecord {
    
    public init(
        type: MyronRecordType,
        fields: [String: MyronValue]
    ) throws {
        try self.init(type: type, fields: fields, location: nil)
    }
    
    public init(
        type: MyronRecordType,
        values: [MyronValue]
    ) throws {
        guard type.fields.count == values.count else {
            let expected = MyronError.IntegerExpectation.exactly(type.fields.count)
            let reason = MyronError.Reason.unexpectedArity(values.count, expected)
            throw MyronError(reason)
        }
        
        let pairs = zip(type.fields, values)
        let fields = Dictionary(uniqueKeysWithValues: pairs)
        try self.init(type: type, fields: fields)
    }
    
    public init(
        type: MyronRecordType,
        values: MyronValue...
    ) throws {
        try self.init(type: type, values: values)
    }
    
}

// MARK: - Swift Operations

extension MyronRecord {
    
    public func get(field: String) throws -> MyronValue {
        return try get(field: field, location: nil)
    }
    
    public func put(field: String, value: MyronValue) throws -> MyronRecord {
        return try put(field: field, value: value, location: nil)
    }

    public func isa(type: MyronRecordType) -> Bool {
        return self.type == type
    }
    
}
