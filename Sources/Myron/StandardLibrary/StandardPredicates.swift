import Foundation

// MARK: - Standard Predicates

struct StandardPredicates: StandardModule {
    
    static let primitiveDefinitions = [
        
        MyronPrimitive(
            primitiveName: "predicate.nothing?",
            representations: ["nothing?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).isNothing)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.number?",
            representations: ["number?"],
            body: { args, location in
                let value = try args.unwrap1(location)
                if value.asInteger != nil { return .boolean(true) }
                if value.asDouble != nil { return .boolean(true) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.integer?",
            representations: ["integer?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asInteger != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.double?",
            representations: ["double?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asDouble != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.string?",
            representations: ["string?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asString != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.boolean?",
            representations: ["boolean?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asBoolean != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.list?",
            representations: ["list?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asList != nil)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.positive?",
            representations: ["positive?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i > 0) }
                if let d = number.asDouble { return .boolean(d > 0) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.negative?",
            representations: ["negative?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i < 0) }
                if let d = number.asDouble { return .boolean(d < 0) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.zero?",
            representations: ["zero?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i == Int.zero) }
                if let d = number.asDouble { return .boolean(d == Double.zero) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.finite?",
            representations: ["finite?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let d = number.asDouble { return .boolean(d.isFinite) }
                if number.asInteger != nil { return .boolean(true) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.infinite?",
            representations: ["infinite?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let d = number.asDouble { return .boolean(d.isInfinite) }
                return .boolean(false)
        }),
        
        MyronPrimitive(
            primitiveName: "predicate.callable?",
            representations: ["callable?"],
            body: { args, location in
                let value = try args.unwrap1(location)
                return .boolean(value.isCallable)
        })
        
    ]
    
}
