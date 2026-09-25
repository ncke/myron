import Foundation

struct StandardRecordType: StandardModule {
    
    // MARK: - Record Type
    
    static let primitiveDefinitions = [
        
        MyronPrimitive(
            primitiveName: "record-type.record-type-name",
            representations: ["record-type-name"],
            signature: StandardSignature([StandardSignature.recOrType1]),
            body: { args, location in
                let rectype = try args.unwrap1(location).unwrapForRecordType(location)
                return .symbol(rectype.name)
            }),
        
        MyronPrimitive(
            primitiveName: "record-type.record-type-fields",
            representations: ["record-type-fields"],
            signature: StandardSignature([StandardSignature.recOrType1]),
            body: { args, location in
                let rectype = try args.unwrap1(location).unwrapForRecordType(location)
                let result = rectype.fields.map { field in MyronValue.symbol(field) }
                return .list(result)
            }),
        
        MyronPrimitive(
            primitiveName: "record-type.has-field?",
            representations: ["has-field?"],
            signature: StandardSignature([StandardSignature.sym1, StandardSignature.recOrType1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let field = try fst.unwrapSymbol(location)
                let rectype = try snd.unwrapForRecordType(location)
                return .boolean(rectype.hasField(field))
            }),
        
        MyronPrimitive(
            primitiveName: "record-type.make-record-type",
            representations: ["make-record-type"],
            signature: StandardSignature([StandardSignature.sym1, StandardSignature.list1]),
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let name = try fst.unwrapSymbol(location)
                let fields = try snd.unwrapList(location).map { fieldSymbol in
                    try fieldSymbol.unwrapSymbol(location)
                }
                
                let rectype = try MyronRecordType(name: name, fields: fields, location: location)
                return .recordType(rectype)
            }),
        
    ]
}
