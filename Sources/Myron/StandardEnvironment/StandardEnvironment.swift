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
        case "nothing": return .nothing
        case "pi": return .double(Double.pi)
            
        // Higher-order lists.
        case "map": return .higherOrder(.map)
        case "filter": return .higherOrder(.filter)
        case "reduce": return .higherOrder(.reduce)
        case "all": return .higherProbe(.all)
        case "any": return .higherProbe(.any)
            
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
        StandardLists.self,
        StandardLogic.self,
        StandardMathematics.self,
        StandardPredicates.self,
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
