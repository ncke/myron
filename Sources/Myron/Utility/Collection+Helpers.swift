import Foundation

extension Collection {

    func mustHaveAtLeast(_ n: Int, _ location: Location?) throws {
        if count < n { throw MyronError(.unexpectedArity(count, .atLeast(n)), at: location) }
    }

    func mustHaveExactly(_ n: Int, _ location: Location?) throws {
        if count != n { throw MyronError(.unexpectedArity(count, .exactly(n)), at: location) }
    }

    func headtail(_ location: Location?) throws -> (Element, Self.SubSequence) {
        try mustHaveAtLeast(1, location)
        let head = self[startIndex]
        let tail = self[index(after: startIndex)...]
        return (head, tail)
    }

    func hasArity(_ n: Int) -> Bool { count == n }

    func unwrap1(_ location: Location?) throws -> Element {
        guard count == 1 else {
            throw MyronError(.unexpectedArity(count, .exactly(1)), at: location)
        }
        return self[startIndex]
    }

    func unwrap2(_ location: Location?) throws -> (Element, Element) {
        guard count == 2 else {
            throw MyronError(.unexpectedArity(count, .exactly(2)), at: location)
        }
        return (self[startIndex], self[index(startIndex, offsetBy: 1)])
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

    func unwrapFirst(_ location: Location?) throws -> Element {
        guard let v = first else {
            throw MyronError(.unexpectedArity(count, .atLeast(1)), at: location)
        }
        return v
    }

    func unwrapSecond(_ location: Location?) throws -> Element {
        guard count > 1 else {
            throw MyronError(.unexpectedArity(count, .atLeast(2)), at: location)
        }
        return self[index(startIndex, offsetBy: 1)]
    }

    func unwrapThird(_ location: Location?) throws -> Element {
        guard count > 2 else {
            throw MyronError(.unexpectedArity(count, .atLeast(3)), at: location)
        }
        return self[index(startIndex, offsetBy: 2)]
    }

}
