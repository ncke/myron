import Foundation

// MARK: - MyronModule

public struct MyronModule {
    public let name: String
    let exportNames: [String]
    let definition: Expression
    let lookup: [String: MyronValue]

    init(
        name: String,
        definition: Expression,
        lookup: [String: MyronValue]
    ) {
        self.name = name
        self.exportNames = lookup.keys.sorted()
        self.definition = definition
        self.lookup = lookup
    }
    
}

// MARK: - Operations

extension MyronModule {

    public var exports: [String] {
        return exportNames
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

extension MyronModule: Equatable, Hashable {

    public static func ==(lhs: MyronModule, rhs: MyronModule) -> Bool {
        return lhs.name == rhs.name && lhs.lookup == rhs.lookup
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(lookup)
    }

}
