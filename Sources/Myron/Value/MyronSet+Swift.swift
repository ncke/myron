import Foundation

// MARK: - MyronSet Set Interoperability

extension MyronSet {
    
    public init(_ set: Set<MyronValue>) {
        self.init(contents: set)
    }
    
    public init<T>(_ set: Set<T>) where T: MyronValueRepresentable {
        self.init(array: set.map { $0 })
    }
    
    public var count: Int {
        return contents.count
    }
    
}

// MARK: - Array Literal Expressibility

extension MyronSet: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = MyronValueRepresentable
    public init(arrayLiteral elements: any ArrayLiteralElement...) {
        self.init(array: elements)
    }
    
}

// MARK: - Sequence Conformance

extension MyronSet: Sequence {

    public func makeIterator() -> Set<MyronValue>.Iterator {
        return Set.makeIterator(self.contents)()
    }
    
}
