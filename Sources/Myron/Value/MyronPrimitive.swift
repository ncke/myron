import Foundation

// MARK: - MyronPrimitive

public struct MyronPrimitive: Sendable {
    typealias Body = @Sendable ([MyronValue], MyronLocation?) throws -> MyronValue
    let primitiveName: String
    let representations: [String]
    let signature: StandardSignature?
    private let body: Body
    
    init(
        primitiveName: String,
        representations: [String],
        signature: StandardSignature? = nil,
        body: @escaping Body
    ) {
        self.primitiveName = primitiveName
        self.representations = representations
        self.signature = signature
        self.body = body
    }
    
    func call(_ arguments: [MyronValue], at location: MyronLocation?) throws -> MyronValue {
        return try body(arguments, location)
    }
    
}

// MARK: - Equatable & Hashable

extension MyronPrimitive: Equatable, Hashable {
    
    public static func ==(lhs: MyronPrimitive, rhs: MyronPrimitive) -> Bool {
        return lhs.primitiveName == rhs.primitiveName
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
    
}

// MARK: - Description

extension MyronPrimitive: CustomStringConvertible {
    
    public var description: String { "<primitive: \(primitiveName)>" }
    
}
