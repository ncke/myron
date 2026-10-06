import Foundation

// MARK: - Standard Predicates

struct StandardPredicates: StandardModule {
    
    static let primitiveDefinitions = [
        
        MyronPrimitive(
            primitiveName: "predicate.nothing?",
            representations: ["nothing?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).isNothing)
        }),

        MyronPrimitive(
            primitiveName: "predicate.something?",
            representations: ["something?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try !args.unwrap1(location).isNothing)
        }),

        MyronPrimitive(
            primitiveName: "predicate.number?",
            representations: ["number?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let value = try args.unwrap1(location)
                if value.asInteger != nil { return .boolean(true) }
                if value.asDouble != nil { return .boolean(true) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.integer?",
            representations: ["integer?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).asInteger != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.double?",
            representations: ["double?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).asDouble != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.set?",
            representations: ["set?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).asSet != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.string?",
            representations: ["string?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).asString != nil)
        }),

        MyronPrimitive(
            primitiveName: "predicate.symbol?",
            representations: ["symbol?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).asSymbol != nil)
        }),

        MyronPrimitive(
            primitiveName: "predicate.boolean?",
            representations: ["boolean?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).asBoolean != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.list?",
            representations: ["list?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                return .boolean(try args.unwrap1(location).asList != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.positive?",
            representations: ["positive?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i > 0) }
                if let d = number.asDouble { return .boolean(d > 0) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.negative?",
            representations: ["negative?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i < 0) }
                if let d = number.asDouble { return .boolean(d < 0) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.zero?",
            representations: ["zero?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i == Int.zero) }
                if let d = number.asDouble { return .boolean(d == Double.zero) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.finite?",
            representations: ["finite?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let number = try args.unwrap1(location)
                if let d = number.asDouble { return .boolean(d.isFinite) }
                if number.asInteger != nil { return .boolean(true) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.infinite?",
            representations: ["infinite?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let number = try args.unwrap1(location)
                if let d = number.asDouble { return .boolean(d.isInfinite) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.nan?",
            representations: ["nan?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let number = try args.unwrap1(location)
                if let d = number.asDouble { return .boolean(d.isNaN) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.callable?",
            representations: ["callable?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let value = try args.unwrap1(location)
                return .boolean(value.isCallable)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.comparable?",
            representations: ["comparable?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let value = try args.unwrap1(location)
                return .boolean(isComparable(value.kind))
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.sortable?",
            representations: ["sortable?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let value = try args.unwrap1(location)
                guard let elements = try? value.unwrapElements(location) else {
                    return .boolean(false)
                }
                guard let fst = elements.first else { return .boolean(true) }
                
                for element in elements {
                    let kind = element.kind
                    if kind != fst.kind || !isComparable(kind) { return .boolean(false) }
                }
                
                return .boolean(true)
        }),

        MyronPrimitive(
            primitiveName: "predicate.module?",
            representations: ["module?"],
            signature: StandardSignature([StandardSignature.any1]),
            body: { args, location in
                let value = try args.unwrap1(location)
                return .boolean(value.isModule)
        }),

        MyronPrimitive(
            primitiveName: "predicate.exports?",
            representations: ["exports?"],
            signature: StandardSignature([
                StandardSignature.strOrSymOrList1,
                StandardSignature.module1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)

                func unwrapName(
                    _ value: MyronValue,
                    allowing kinds: Set<MyronValue.Kind>
                ) throws -> String {
                    guard let name = value.asString ?? value.asSymbol else {
                        let reason = MyronError.Reason.unexpectedType(value.kind, kinds)
                        throw MyronError(reason, at: location)
                    }

                    return name
                }

                let names = try fst.asList?.map { element in
                    try unwrapName(element, allowing: [.string, .symbol])
                } ?? [unwrapName(fst, allowing: [.string, .symbol, .list])]

                let module = try snd.unwrapModule(location)
                return .boolean(names.allSatisfy { name in module[name] != nil })
        })

    ]
    
}

// MARK: - Helpers

extension StandardPredicates {
    
    private static func isComparable(_ kind: MyronValue.Kind) -> Bool {
        switch kind {
        case .double, .integer, .string: return true
        default: return false
        }
    }
    
}
