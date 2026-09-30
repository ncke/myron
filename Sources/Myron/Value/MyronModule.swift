import Foundation

// MARK: - MyronModule

public struct MyronModule {
    public let name: String
    let lookup: [String: MyronValue]

    init(name: String, lookup: [String: MyronValue]) {
        self.name = name
        self.lookup = lookup
    }
    
}

// MARK: - Operations

extension MyronModule {

    public var exports: [String] {
        return lookup.keys.sorted()
    }

    public subscript(_ name: String) -> MyronValue? {
        get { lookup[name] }
    }

}

// MARK: - Description

extension MyronModule: CustomStringConvertible {

    public var description: String {
        return "<module: \(name)>"
    }

}

// MARK:- Equatable & Hashable

extension MyronModule: Equatable, Hashable {}
