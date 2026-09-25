import Foundation

// MARK: - MyronRecordType

public struct MyronRecordType: Sendable {
    public let name: String
    public let fields: [String]
    let positions: [String: Int]
    
    init(name: String, fields: [String], location: MyronLocation?) throws {
        try MyronValue.validateAsName(name, location: location)
        self.name = name
        self.fields = fields
                
        var positions = [String: Int]()
        for (idx, field) in fields.enumerated() {
            try MyronValue.validateAsName(field, location: location)
            guard positions[field] == nil else {
                throw MyronError(.duplicateField(field, name), at: location)
            }
            positions[field] = idx
        }
        
        self.positions = positions
    }
    
    public init(name: String, fields: [String]) throws {
        try self.init(name: name, fields: fields, location: nil)
    }
    
    public init(name: String, fields: String...) throws {
        try self.init(name: name, fields: fields)
    }
    
    public func hasField(_ field: String) -> Bool {
        return positions[field] != nil
    }
    
}

// MARK: - Description

extension MyronRecordType: CustomStringConvertible {
    
    public var description: String {
        let describeFields = (!fields.isEmpty ? " " : "") + fields.joined(separator: " ")
        return "<record-type: \(name)\(describeFields)>"
    }
    
}

// MARK: - Equatable & Hashable

extension MyronRecordType: Equatable, Hashable {
    
    public static func ==(lhs: MyronRecordType, rhs: MyronRecordType) -> Bool {
        lhs.name == rhs.name && lhs.fields == rhs.fields
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(fields)
    }

}
