import Foundation

// MARK: - Standard Predicates

struct StandardPredicates: StandardModule {
    
    static let primitiveDefinitions = [
        
        MyronXPrimitive(
            primitiveName: "comparison.nothing?",
            representations: ["nothing?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).isNothing)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.number?",
            representations: ["number?"],
            body: { args, location in
                let value = try args.unwrap1(location)
                if value.asInteger != nil { return .boolean(true) }
                if value.asDouble != nil { return .boolean(true) }
                return .boolean(false)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.integer?",
            representations: ["integer?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asInteger != nil)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.double?",
            representations: ["double?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asDouble != nil)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.string?",
            representations: ["string?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asString != nil)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.boolean?",
            representations: ["boolean?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asBoolean != nil)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.list?",
            representations: ["list?"],
            body: { args, location in
                return .boolean(try args.unwrap1(location).asList != nil)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.positive?",
            representations: ["positive?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i > 0) }
                if let d = number.asDouble { return .boolean(d > 0) }
                return .boolean(false)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.negative?",
            representations: ["negative?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i < 0) }
                if let d = number.asDouble { return .boolean(d < 0) }
                return .boolean(false)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.zero?",
            representations: ["zero?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let i = number.asInteger { return .boolean(i == Int.zero) }
                if let d = number.asDouble { return .boolean(d == Double.zero) }
                return .boolean(false)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.finite?",
            representations: ["finite?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let d = number.asDouble { return .boolean(d.isFinite) }
                if number.asInteger != nil { return .boolean(true) }
                return .boolean(false)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.infinite?",
            representations: ["infinite?"],
            body: { args, location in
                let number = try args.unwrap1(location)
                if let d = number.asDouble { return .boolean(d.isInfinite) }
                return .boolean(false)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.equatable?",
            representations: ["equatable?"],
            body: { args, location in
                let value = try args.unwrap1(location)
                return .boolean(value.isEquatable)
        }),
        
        MyronXPrimitive(
            primitiveName: "comparison.callable?",
            representations: ["callable?"],
            body: { args, location in
                let value = try args.unwrap1(location)
                return .boolean(value.isCallable)
        })
        
    ]
    
}
