import Foundation

// MARK: - MyronPrimitive

public struct MyronPrimitive: Sendable {
    typealias Body = @Sendable ([MyronValue], MyronLocation?) throws -> MyronValue
    let id: Int?
    let primitiveName: String
    let representations: [String]
    let signature: Result<MyronSignature, MyronError>?
    private let body: Body

    init(
        id: Int? = nil,
        primitiveName: String,
        representations: [String],
        signature: String? = nil,
        body: @escaping Body
    ) {
        self.id = id
        self.primitiveName = primitiveName
        self.representations = representations
        self.signature = signature.map(Self.parseSignature)
        self.body = body
    }

    func call(_ arguments: [MyronValue], at location: MyronLocation?) throws -> MyronValue {
        return try body(arguments, location)
    }

}

// MARK: - Signature

extension MyronPrimitive {

    private static func parseSignature(_ string: String) -> Result<MyronSignature, MyronError> {
        do {
            return .success(try MyronSignature(string))
        } catch let error as MyronError {
            return .failure(error)
        } catch {
            return .failure(MyronError(.internal("unexpected error parsing signature: \(error)")))
        }
    }

}

// MARK: - Equatable & Hashable

extension MyronPrimitive: Equatable, Hashable {
    
    public static func ==(lhs: MyronPrimitive, rhs: MyronPrimitive) -> Bool {
        if lhs.id != nil || rhs.id != nil { return lhs.id == rhs.id }
        return lhs.primitiveName == rhs.primitiveName
    }
    
    public func hash(into hasher: inout Hasher) {
        if let id = id { hasher.combine(id) } else { hasher.combine(primitiveName) }
    }
    
}

// MARK: - Description

extension MyronPrimitive: CustomStringConvertible {
    
    public var description: String { "<primitive: \(primitiveName)>" }
    
}
