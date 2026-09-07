import Foundation

// MARK: - Dispatcher

struct Dispatcher: @unchecked Sendable {

    struct Pattern {
        let argumentIndex: Int
        let match: Value.Kind
        let target:  Primitive

        init(_ argumentIndex: Int, _ match: Value.Kind, _ target: @escaping Primitive) {
            self.argumentIndex = argumentIndex
            self.match = match
            self.target = target
        }
    }

    private let patterns: [Pattern]

    init(_ patterns: [Pattern]) {
        self.patterns = patterns
    }

    func dispatch(_ args: [Value], _ apply: Applier, _ location: Location?) throws -> Value {
        var arityMet = false
        var gotKinds = Set<Value.Kind>()

        for pattern in patterns {
            guard
                pattern.argumentIndex >= 0,
                pattern.argumentIndex < args.count
            else {
                continue
            }

            arityMet = true
            guard args[pattern.argumentIndex].kind == pattern.match else {
                gotKinds.insert(args[pattern.argumentIndex].kind)
                continue
            }

            return try pattern.target(args, apply, location)
        }

        if !arityMet {
            throw MyronError(.unexpectedArity(args.count, .unspecified), at: location)
        }

        let got = gotKinds.count == 1 ? gotKinds.first : nil
        let expectations = Set(patterns.map(\.match))
        throw MyronError(.unexpectedType(got, expectations), at: location)
    }

}
