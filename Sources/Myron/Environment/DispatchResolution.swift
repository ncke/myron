import Foundation

/*
 
 Red herring! But may need some of this code for resolution elsewhere shortly.

// MARK: - DispatchResolution

final class DispatchResolution {
    let baseEnvironment: Environment
    let targetName: String
    let targetArgumentKinds: [MyronValue.Kind]
    let location: MyronLocation?
    
    enum ResolutionFailure {
        case unresolvedName
        case unresolvedArity(Set<Int>)
        case unresolvedKinds(Set<[[MyronValue.Kind]]>)
    }
    
    private var resolutionFailure = ResolutionFailure.unresolvedName
    
    init(
        baseEnvironment: Environment,
        targetName: String,
        targetArgumentKinds: [MyronValue.Kind],
        location: MyronLocation?
    ) {
        self.baseEnvironment = baseEnvironment
        self.targetName = targetName
        self.targetArgumentKinds = targetArgumentKinds
        self.location = location
    }
    
}

// MARK: - Resolution

extension DispatchResolution {
    
    func resolve() throws -> DispatchRegistry.Execution {
        var nextEnvironment: Environment? = baseEnvironment
        while let environment = nextEnvironment {
            if let registration = try innerResolve(in: environment) {
                return registration.execution
            }
            
            nextEnvironment = environment.outer
        }
        
        let error = generateErrorFromFailure(resolutionFailure)
        throw error
    }
    
    private func innerResolve(
        in environment: Environment
    ) throws -> DispatchRegistry.Registration? {
        let registrations = environment.dispatchRegistry.registrations
        var resolution: DispatchRegistry.Registration?
        let targetArity = targetArgumentKinds.count
        
        for registration in registrations {
            guard registration.names.contains(targetName) else {
                continue
            }
            
            guard registration.arity == targetArity else {
                let expectedArity = Set([registration.arity])
                let failure = ResolutionFailure.unresolvedArity(expectedArity)
                resolutionFailure = resolutionFailure.aggregateFailure(failure)
                continue
            }
            
            let zipped = zip(targetArgumentKinds, registration.signature)
            let mismatch = zipped.first { (targetKind, signatureKinds) in
                !signatureKinds.contains(targetKind)
            }
            
            guard mismatch == nil else {
                let expectedKinds = Set([registration.signature])
                let failure = ResolutionFailure.unresolvedKinds(expectedKinds)
                resolutionFailure = resolutionFailure.aggregateFailure(failure)
                continue
            }
            
            guard resolution == nil else {
                let reason = MyronError.Reason.multipleResolutions(targetName, targetArgumentKinds)
                throw MyronError(reason, at: location)
            }
            
            resolution = registration
        }
        
        return resolution
    }
    
}

// MARK: - Failure Error Generation

extension DispatchResolution {
    
    private func generateErrorFromFailure(_ failure: ResolutionFailure) -> MyronError {
        switch failure {
            
        case .unresolvedName:
            return MyronError(.unresolvedName(targetName), at: location)
            
        case .unresolvedArity(let expectedArities):
            let got = targetArgumentKinds.count
            let expected = integerExpection(fromArities: expectedArities)
            return MyronError(.unexpectedArity(got, expected), at: location)
            
        case .unresolvedKinds:
            return MyronError(.unresolvedSignature(targetName, targetArgumentKinds))
            
        }
    }
    
    private func integerExpection(fromArities arities: Set<Int>) -> MyronError.IntegerExpectation {
        if arities.count == 1, let exact = arities.first {
            return MyronError.IntegerExpectation.exactly(exact)
        } else if arities.count > 1, let minimum = arities.min() {
            return MyronError.IntegerExpectation.atLeast(minimum)
        }
        
        return MyronError.IntegerExpectation.unspecified
    }
    
}

// MARK: - Failure Semantics

extension DispatchResolution.ResolutionFailure {
    
    func aggregateFailure(
        _ failure: DispatchResolution.ResolutionFailure
    ) -> DispatchResolution.ResolutionFailure {
        switch failure {
            
        case .unresolvedName:
            return self
            
        case .unresolvedArity(let expectedArity):
            switch self {
            case .unresolvedName: return .unresolvedArity(expectedArity)
            case .unresolvedArity(let expectedArities): return .unresolvedArity(expectedArities.union(expectedArity))
            case .unresolvedKinds: return self
            }
            
        case .unresolvedKinds(let expectedKinds):
            switch self {
            case .unresolvedName, .unresolvedArity: return .unresolvedKinds(expectedKinds)
            case .unresolvedKinds(let previous): return .unresolvedKinds(previous.union(expectedKinds))
            }
        }
    }
    
}

*/
