import Foundation

// MARK: - StandardEnvironment

final class StandardEnvironment {
    private var definitions = [String: MyronPrimitive]()
    
    init() {
        loadPrimitives()
    }
    
    func lookup(_ representation: String) -> MyronValue? {
        switch representation {
            
        // Constants.
        case "infinity": return .double(.infinity)
        case "nan": return .double(.nan)
        case "nothing": return .nothing
        case "pi": return .double(Double.pi)

        // Higher-order functions.
        case "all": return .higherProbe(.all)
        case "apply": return .higherOrder(.apply)
        case "any": return .higherProbe(.any)
        case "filter": return .higherOrder(.filter)
        case "foldr": return .higherOrder(.foldr)
        case "map": return .higherOrder(.map)
        case "reduce": return .higherOrder(.reduce)

        default :break
        }
        
        guard let primitive = definitions[representation] else {
            return nil
        }
        
        return .primitive(primitive)
    }
    
}

// MARK: - StandardModule & Loading

protocol StandardModule: Sendable {
    static var primitiveDefinitions: [MyronPrimitive] { get }
}

extension StandardEnvironment {
    
    static let modules: [any StandardModule.Type] = [
        StandardAlist.self,
        StandardComparison.self,
        StandardHashmap.self,
        StandardKinds.self,
        StandardLists.self,
        StandardLogic.self,
        StandardMathematics.self,
        StandardOrdering.self,
        StandardPredicates.self,
        StandardRecord.self,
        StandardRecordType.self,
        StandardSet.self,
        StandardStrings.self
    ]
    
    private func loadPrimitives() {
        self.definitions = [:]
        var loaded = [String: [MyronPrimitive]]()
        
        for module in Self.modules {
            module.primitiveDefinitions.forEach { primitive in
                for representation in primitive.representations {
                    var primitives = loaded[representation] ?? []
                    primitives.append(primitive)
                    loaded[representation] = primitives
                }
            }
        }
        
        for (representation, primitives) in loaded {
            if primitives.count == 1, let primitive = primitives.first {
                self.definitions[representation] = primitive
                continue
            }
            
            let resolver = StandardResolver.make(
                representation: representation,
                primitives: primitives)
            
            self.definitions[representation] = resolver
        }
    }
    
}
