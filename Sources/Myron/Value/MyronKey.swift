import Foundation

// MARK: - Key

public enum MyronKey {
    case boolean(Bool)
    case double(Double)
    case integer(Int)
    case string(String)
}

// MARK: - Conformances

extension MyronKey: Equatable, Hashable, Sendable {}

extension MyronKey: CustomStringConvertible {

    public var description: String {
        return "\(self.value)"
    }

}

// MARK: - Key Helpers

extension MyronKey {

    public init(_ value: MyronValue) throws {
        try self.init(value, at: nil)
    }

    init(_ value: MyronValue, at location: MyronLocation?) throws {
        switch value {
        case .boolean(let b): self = .boolean(b)
        case .double(let d) where d.isFinite: self = .double(d)
        case .integer(let i): self = .integer(i)
        case .string(let s): self = .string(s)
        default:
            throw MyronError(.invalidKey(value.kind), at: location)
        }
    }

    public var value: MyronValue {
        switch self {
        case .boolean(let b): return .boolean(b)
        case .double(let d): return .double(d)
        case .integer(let i): return .integer(i)
        case .string(let s): return .string(s)
        }
    }

}
