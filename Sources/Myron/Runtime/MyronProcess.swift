import Foundation

// MARK: - Myron Process

public struct MyronProcess: Hashable, Sendable {
    let value: Int

    init(_ value: Int) {
        self.value = value
    }

}

// MARK: - Custom String Convertible

extension MyronProcess: CustomStringConvertible {

    public var description: String { "<process: \(value)>" }

}
