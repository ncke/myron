import Foundation

extension Collection {

    func mustHaveAtLeast(_ n: Int, _ location: Location?) throws {
        if count < n { throw MyronError(.unexpectedArity(count, .atLeast(n)), at: location) }
    }

    func mustHaveAtLeast(_ n: Int) throws where Self: Locatable {
        if count < n { throw MyronError(.unexpectedArity(count, .atLeast(n)), at: self.location) }
    }

    func mustHaveExactly(_ n: Int, _ location: Location?) throws {
        if count != n { throw MyronError(.unexpectedArity(count, .exactly(n)), at: location) }
    }

    func mustHaveExactly(_ n: Int) throws where Self: Locatable {
        if count != n { throw MyronError(.unexpectedArity(count, .exactly(n)), at: self.location) }
    }

    func headtail(_ location: Location?) throws -> (Element, Self.SubSequence) {
        try mustHaveAtLeast(1, location)
        let head = self[startIndex]
        let tail = self[index(after: startIndex)...]
        return (head, tail)
    }

    func headtail() throws -> (Element, Self.SubSequence) where Self: Locatable {
        return try headtail(self.location)
    }

    func hasArity(_ n: Int) -> Bool { count == n }

    func unwrap1(_ location: Location?) throws -> Element {
        guard count == 1 else {
            throw MyronError(.unexpectedArity(count, .exactly(1)), at: location)
        }
        return self[startIndex]
    }

    func unwrap1() throws -> Element where Self: Locatable {
        return try unwrap1(self.location)
    }

    func unwrap2(_ location: Location?) throws -> (Element, Element) {
        guard count == 2 else {
            throw MyronError(.unexpectedArity(count, .exactly(2)), at: location)
        }
        return (self[startIndex], self[index(startIndex, offsetBy: 1)])
    }

    func unwrap2() throws -> (Element, Element) where Self: Locatable {
        return try unwrap2(self.location)
    }

    func unwrap3(_ location: Location?) throws -> (Element, Element, Element) {
        guard count == 3 else {
            throw MyronError(.unexpectedArity(count, .exactly(3)), at: location)
        }
        let i0 = startIndex
        let i1 = index(startIndex, offsetBy: 1)
        let i2 = index(startIndex, offsetBy: 2)

        return (self[i0], self[i1], self[i2])
    }

    func unwrap3() throws -> (Element, Element, Element) where Self: Locatable {
        return try unwrap3(self.location)
    }

    func unwrapFirst(_ location: Location?) throws -> Element {
        guard let v = first else {
            throw MyronError(.unexpectedArity(count, .atLeast(1)), at: location)
        }
        return v
    }

    func unwrapFirst() throws -> Element where Self: Locatable {
        return try unwrapFirst(self.location)
    }

    func unwrapSecond(_ location: Location?) throws -> Element {
        guard count > 1 else {
            throw MyronError(.unexpectedArity(count, .atLeast(2)), at: location)
        }
        return self[index(startIndex, offsetBy: 1)]
    }

    func unwrapSecond() throws -> Element where Self: Locatable {
        return try unwrapSecond(self.location)
    }

    func unwrapThird(_ location: Location?) throws -> Element {
        guard count > 2 else {
            throw MyronError(.unexpectedArity(count, .atLeast(3)), at: location)
        }
        return self[index(startIndex, offsetBy: 2)]
    }

    func unwrapThird() throws -> Element where Self: Locatable {
        return try unwrapThird(self.location)
    }

}
