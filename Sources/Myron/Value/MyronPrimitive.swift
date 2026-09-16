import Foundation

// MARK: - MyronPrimitive

public struct MyronXPrimitive: Sendable {
    typealias Body = @Sendable ([MyronValue], MyronLocation?) throws -> MyronValue
    let name: String
    let representations: [String]
    let body: Body
    
    init(name: String, representations: [String]? = nil, body: @escaping Body) {
        self.name = name
        if let representations = representations {
            self.representations = representations
        } else {
            let representation = Self.representation(from: name)
            self.representations = [representation]
        }
        self.body = body
    }
    
    func call(_ arguments: [MyronValue], at location: MyronLocation?) throws -> MyronValue {
        return try body(arguments, location)
    }
    
    private static func representation(from name: String) -> String {
        guard let last = name.split(separator: ".").last else {
            return name
        }
        
        return String(last)
    }
    
}

// MARK: - Equatable & Hashable

extension MyronXPrimitive: Equatable, Hashable {
    
    public static func ==(lhs: MyronXPrimitive, rhs: MyronXPrimitive) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
}

// MARK: - Description

extension MyronXPrimitive: CustomStringConvertible {
    
    public var description: String { "<primitive: \(name)>" }
    
}
