import Foundation

// MARK: - Dispatcher

struct Dispatcher: @unchecked Sendable {

    struct Pattern {
        let argumentIndex: Int
        let match: MyronValue.Kind
        let target:  MyronPrimitive

        init(_ argumentIndex: Int, _ match: MyronValue.Kind, _ target: @escaping MyronPrimitive) {
            self.argumentIndex = argumentIndex
            self.match = match
            self.target = target
        }
    }

    private let patterns: [Pattern]
    private let sharedArity: MyronError.IntegerExpectation?

    init(_ patterns: [Pattern], sharedArity: MyronError.IntegerExpectation? = nil) {
        self.patterns = patterns
        self.sharedArity = sharedArity
    }

    func dispatch(_ args: [MyronValue], _ location: MyronLocation?) throws -> MyronValue {
        var arityMet = false
        var gotKinds = Set<MyronValue.Kind>()

        for pattern in patterns {
            guard
                pattern.argumentIndex >= 0,
                pattern.argumentIndex < args.count
            else {
                continue
            }

            if let sharedArity {
                switch sharedArity {
                case .atLeast(let count): arityMet = arityMet || args.count >= count
                case .atMost(let count): arityMet = arityMet || args.count <= count
                case .exactly(let count): arityMet = arityMet || args.count == count
                case .unspecified: arityMet = true
                }
            } else {
                arityMet = true
            }

            guard args[pattern.argumentIndex].kind == pattern.match else {
                gotKinds.insert(args[pattern.argumentIndex].kind)
                continue
            }

            return try pattern.target(args, location)
        }

        if !arityMet {
            let expect = sharedArity ?? .unspecified
            throw MyronError(.unexpectedArity(args.count, expect), at: location)
        }

        let got = gotKinds.count == 1 ? gotKinds.first : nil
        let expectations = Set(patterns.map(\.match))
        throw MyronError(.unexpectedType(got, expectations), at: location)
    }

}
