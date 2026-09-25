import Foundation

// MARK: - StandardStrings

struct StandardStrings: StandardModule {
    
    static let primitiveDefinitions = [
        
        // MARK: String Sequence
        
        MyronPrimitive(
            primitiveName: "string.head",
            representations: ["head"],
            signature: StandardSignature([StandardSignature.str1]),
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                guard let head = str.first else { return .nothing }
                return .string(String(head))
            }),
        
        MyronPrimitive(
            primitiveName: "string.tail",
            representations: ["tail"],
            signature: StandardSignature([StandardSignature.str1]),
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                let tail = String(str.dropFirst())
                return .string(tail)
            }),
        
        MyronPrimitive(
            primitiveName: "string.initial",
            representations: ["init"],
            signature: StandardSignature([StandardSignature.str1]),
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                let result = String(str.dropLast())
                return .string(result)
            }),
        
        MyronPrimitive(
            primitiveName: "string.last",
            representations: ["last"],
            signature: StandardSignature([StandardSignature.str1]),
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                guard let last = str.last else { return .nothing }
                return .string(String(last))
            }),
        
        MyronPrimitive(
            primitiveName: "string.take",
            representations: ["take"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.str1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let str = try snd.unwrapString(location)
                let take = String(str.prefix(count))
                return .string(take)
            }),
        
        MyronPrimitive(
            primitiveName: "string.drop",
            representations: ["drop"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.str1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let str = try snd.unwrapString(location)
                let drop = String(str.dropFirst(count))
                return .string(drop)
            }),
        
        MyronPrimitive(
            primitiveName: "string.take-last",
            representations: ["take-last"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.str1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let elements = try snd.unwrapString(location)
                let take = String(elements.suffix(count))
                return .string(take)
            }),
        
        MyronPrimitive(
            primitiveName: "string.drop-last",
            representations: ["drop-last"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.str1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let count = try fst.unwrapInteger(location)
                guard count >= 0 else { throw MyronError(.cannotBeNegative, at: location) }

                let elements = try snd.unwrapString(location)
                let prefixCount = max(0, elements.count - count)
                let drop = String(elements.prefix(prefixCount))
                return .string(drop)
            }),
        
        MyronPrimitive(
            primitiveName: "string.length",
            representations: ["length"],
            signature: StandardSignature([StandardSignature.str1]),
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                return .integer(str.count)
            }),
        
        MyronPrimitive(
            primitiveName: "string.empty?",
            representations: ["empty?"],
            signature: StandardSignature([StandardSignature.str1]),
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                return .boolean(str.count == 0)
            }),
        
        MyronPrimitive(
            primitiveName: "string.append",
            representations: ["append"],
            signature: StandardSignature([StandardSignature.str1], allowsVariadic: .homogenous),
            body: { args, location in
                try args.mustHaveAtLeast(1, location)
                var result = ""
                for arg in args {
                    let str = try arg.unwrapString(location)
                    result += str
                }
                return .string(result)
            }),
        
        MyronPrimitive(
            primitiveName: "string.reverse",
            representations: ["reverse"],
            signature: StandardSignature([StandardSignature.str1]),
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                return .string(String(str.reversed()))
            }),
        
        MyronPrimitive(
            primitiveName: "string.nth",
            representations: ["nth"],
            signature: StandardSignature([StandardSignature.int1, StandardSignature.str1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let index = try fst.unwrapInteger(location)
                let str = try snd.unwrapString(location)

                guard index >= 0, index < str.count else {
                    throw MyronError(.subscriptOutOfBounds(index, str.count), at: location)
                }

                let char = str[str.index(str.startIndex, offsetBy: index)]
                return .string(String(char))
            }),
        
        MyronPrimitive(
            primitiveName: "string.contains?",
            representations: ["contains?"],
            signature: StandardSignature([StandardSignature.any1, StandardSignature.str1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let target = try fst.unwrapString(location)
                let str = try snd.unwrapString(location)
                if target.isEmpty { return .boolean(true) }
                return .boolean(str.contains(target))
            }),
        
        // MARK: String Native
        
        MyronPrimitive(
            primitiveName: "string.explode",
            representations: ["explode"],
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                let pieces = str.map { ch in MyronValue.string(String(ch)) }
                return .list(pieces)
            }),
        
        MyronPrimitive(
            primitiveName: "string.implode",
            representations: ["implode"],
            body: { args, location in
                try args.mustHaveAtLeast(1, location)
                let sep: String
                let elements: [MyronValue]

                if args[0].kind == .string {
                    guard args.count == 2 else {
                        throw MyronError(.unexpectedArity(args.count, .exactly(2)), at: location)
                    }
                    sep = try args[0].unwrapString(location)
                    elements = try args[1].unwrapList(location)
                } else {
                    guard args.count == 1 else {
                        throw MyronError(.unexpectedArity(args.count, .exactly(1)), at: location)
                    }
                    sep = ""
                    elements = try args[0].self.unwrapList(location)
                }

                let descriptions = elements.map { element in
                    switch element {
                    case .string(let str): return str
                    default: return element.description
                    }
                }

                return .string(descriptions.joined(separator: sep))
            }),
        
        MyronPrimitive(
            primitiveName: "string.string",
            representations: ["string"],
            body: { args, location in
                let src = try args.unwrap1(location)
                if src.kind == .string { return src }
                return .string(src.description)
            }),
        
        MyronPrimitive(
            primitiveName: "string.lowercase",
            representations: ["lowercase"],
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                return .string(str.lowercased())
            }),
        
        MyronPrimitive(
            primitiveName: "string.uppercase",
            representations: ["uppercase"],
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                return .string(str.uppercased())
            }),
        
        MyronPrimitive(
            primitiveName: "string.trim",
            representations: ["trim"],
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                return .string(str.trimmingCharacters(in: .whitespacesAndNewlines))
            }),
        
        MyronPrimitive(
            primitiveName: "string.lines",
            representations: ["lines"],
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                let lines = str
                    .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                    .map { lineStr in MyronValue.string(String(lineStr)) }

                return .list(lines)
            }),
        
        MyronPrimitive(
            primitiveName: "string.words",
            representations: ["words"],
            body: { args, location in
                let str = try args.unwrap1(location).unwrapString(location)
                let words = str
                    .split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
                    .map { wordStr in MyronValue.string(String(wordStr)) }

                return .list(words)
            })
        
    ]

}
