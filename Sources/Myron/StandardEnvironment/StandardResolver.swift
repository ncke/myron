import Foundation

// MARK: - Standard Resolver

struct StandardResolver {
    
    static func make(representation: String, primitives: [MyronPrimitive]) -> MyronPrimitive {
        let names = primitives.map { p in p.primitiveName }.joined(separator: "+")
        let contenders = "resolver:\(names)"
        let resolverName = "*." + representation
                
        let resolverBody: MyronPrimitive.Body = {
            args, location in
            
            let argKinds = args.map { arg in arg.kind }
            var matchedIdxs = [Int]()
            var matchedConstraints = [[StandardSignature.Constraint]]()
            var unmetArities = [MyronError.IntegerExpectation]()
            var deepestPosition: Int?
            var allowedAtDeepest = Set<MyronValue.Kind>()

            for (idx, primitive) in primitives.enumerated() {
                guard let signature = primitive.signature else {
                    let explain = "cannot resolve against a nil signature, in: \(contenders)"
                    throw MyronError(.internal(explain), at: location)
                }

                let result = try signature.matchesKinds(argKinds)

                switch result {

                case .match(let constraints):
                    matchedIdxs.append(idx)
                    matchedConstraints.append(constraints)

                case .unmetArity(let arity):
                    if !unmetArities.contains(arity) { unmetArities.append(arity) }

                case .unmetKind(let position, let allowed):
                    if position > (deepestPosition ?? -1) {
                        deepestPosition = position
                        allowedAtDeepest = allowed
                    } else if position == deepestPosition {
                        allowedAtDeepest.formUnion(allowed)
                    }
                }
            }

            guard !matchedIdxs.isEmpty else {
                if let deepestPosition, deepestPosition < argKinds.count {
                    let got = argKinds[deepestPosition]
                    let reason = MyronError.Reason.unexpectedType(got, allowedAtDeepest)
                    throw MyronError(reason, at: location)
                }

                if unmetArities.count == 1, let unmetArity = unmetArities.first {
                    let reason = MyronError.Reason.unexpectedArity(args.count, unmetArity)
                    throw MyronError(reason, at: location)
                }

                var expected = Set<String>()
                for primitive in primitives {
                    guard let signature = primitive.signature else { continue }
                    expected.formUnion(try signature.describeForms(representation: representation))
                }
                
                let got = args.map { arg in "\(arg.kind)" }.joined(separator: " ")
                let ordered = Array(expected).sorted()
                let reason = MyronError.Reason.couldNotResolve(representation, got, ordered)
                throw MyronError(reason, at: location)
            }

            var maximal = [Int]()
            for candidate in matchedIdxs.indices {
                var isDominated = false

                for rival in matchedIdxs.indices where rival != candidate {
                    let comparison = try StandardSignature.compareSpecificity(
                        matchedConstraints[rival],
                        to: matchedConstraints[candidate])

                    if comparison == .moreSpecific {
                        isDominated = true
                        break
                    }
                }

                if !isDominated { maximal.append(candidate) }
            }

            guard maximal.count == 1, let winner = maximal.first else {
                guard !maximal.isEmpty else {
                    let explain = "no maximal candidate in: \(contenders)"
                    throw MyronError(.internal(explain), at: location)
                }

                let candidates = maximal
                    .map { candidate in primitives[matchedIdxs[candidate]].primitiveName }
                    .sorted()

                let got = argKinds.map { kind in "\(kind)" }.joined(separator: " ")
                let reason = MyronError.Reason.ambiguousResolution(representation, got, candidates)
                throw MyronError(reason, at: location)
            }

            return try primitives[matchedIdxs[winner]].call(args, at: location)
        }
        
        let resolverPrimitive = MyronPrimitive(
            primitiveName: resolverName,
            representations: [],
            body: resolverBody)
        
        return resolverPrimitive
    }
    
}
