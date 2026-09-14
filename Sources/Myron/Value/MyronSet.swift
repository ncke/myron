import Foundation

// MARK: - MyronSet

public struct MyronSet {
    private var atoms: Set<MyronKey>
    private var structures: [MyronValue]

    public init() {
        self.atoms = []
        self.structures = []
    }


}

// MARK: - Membership

extension MyronSet {

    public func insert(_ member: MyronValue) {
        
    }

}


// MARK: - Constrain to Equatable Kinds

extension MyronSet {

    private func checkValidty(of value: MyronValue, location: MyronLocation?) throws {
        guard value.isEquatable else {
            throw MyronError(.invalidSetMember(value.kind), at: location)
        }
    }

}
