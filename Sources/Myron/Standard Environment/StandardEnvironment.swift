import Foundation

// MARK: - StandardEnvironment

final class StandardEnvironment {
    private var definitions = [String: [MyronXPrimitive]]()
    
    init() {
        loadPrimitives()
    }
    
    fileprivate func insert(_ primitive: MyronXPrimitive) {
        for representation in primitive.representations {
            var primitives = definitions[representation] ?? []
            primitives.append(primitive)
            definitions[representation] = primitives
        }
    }
    
    func lookup(_ representation: String) -> MyronValue? {
        switch representation {
        case "nothing": return .nothing
        case "pi": return .double(Double.pi)
        default :break
        }
        
        guard let primitives = definitions[representation] else {
            return nil
        }
        
        if primitives.count == 1, let primitive = primitives.first {
            return .xprimitive(primitive)
        }
        
        // Will return a resolver.
        fatalError()
    }
    
}

// MARK: - Resolution

extension StandardEnvironment {
    
    // Todo.
    
}

// MARK: - StandardModule & Loading

protocol StandardModule: Sendable {
    static var primitiveDefinitions: [MyronXPrimitive] { get }
}

extension StandardEnvironment {
    
    private static let modules: [any StandardModule.Type] = [
        StandardAlist.self,
        StandardComparison.self,
        StandardHashmap.self,
        StandardLists.self,
        StandardLogic.self,
        StandardMathematics.self,
        StandardPredicates.self,
        StandardStrings.self
    ]
    
    private func loadPrimitives() {
        for module in Self.modules {
            module.primitiveDefinitions.forEach { primitive in insert(primitive) }
        }
    }
    
}

// MARK: - Legacy Standard Environment

extension Environment {

    func standardLookup(_ name: String) -> MyronValue? {
        switch name {

        // Sequences.
        case "head": return .primitive(StandardSequence.head)
        case "tail": return .primitive(StandardSequence.tail)
        case "init": return .primitive(StandardSequence.initial)
        case "last": return .primitive(StandardSequence.last)
        case "take": return .primitive(StandardSequence.take)
        case "drop": return .primitive(StandardSequence.drop)
        case "length": return .primitive(StandardSequence.length)
        case "empty?": return .primitive(StandardSequence.empty)
        case "append": return .primitive(StandardSequence.append)
        case "reverse": return .primitive(StandardSequence.reverse)
        case "nth": return .primitive(StandardSequence.nth)
        case "contains": return .primitive(StandardSequence.contains)

        // Higher-order lists.
        case "map": return .higherOrder(.map)
        case "filter": return .higherOrder(.filter)
        case "reduce": return .higherOrder(.reduce)
        case "all": return .higherProbe(.all)
        case "any": return .higherProbe(.any)

        // Associations.
        case "get": return .primitive(StandardAssociative.get)
        case "get-or": return .primitive(StandardAssociative.getOr)
        case "put": return .primitive(StandardAssociative.put)
        case "remove": return .primitive(StandardAssociative.remove)
        case "has-key?": return .primitive(StandardAssociative.hasKey)
        case "keys": return .primitive(StandardAssociative.keys)
        case "values": return .primitive(StandardAssociative.values)

        default:
            return nil
        }
    }

    static func unimplemented(args: [MyronValue], location: MyronLocation?) throws -> MyronValue {
        throw MyronError(.unimplementedFeature, at: location)
    }

}
