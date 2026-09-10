import Foundation

// MARK: - Key

extension Value {

    enum Key {
        case boolean(Bool)
        case double(Double)
        case integer(Int)
        case string(String)
    }

}

// MARK: - Conformances

extension Value.Key: Equatable, Hashable {}

// MARK: - Key Helpers

extension Value.Key {

    static func fromValue(_ value: Value, at location: Location?) throws -> Value.Key {
        switch value {
        case .boolean(let b): return .boolean(b)
        case .double(let d):
            guard d.isFinite else { throw MyronError(.invalidKey(value.kind), at: location) }
            return .double(d)
        case .integer(let i): return .integer(i)
        case .string(let s): return .string(s)
        default:
            throw MyronError(.invalidKey(value.kind), at: location)
        }
    }

}
