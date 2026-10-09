import Foundation

struct StandardRecord: StandardModule {
    
    // MARK: - Record
    
    static let primitiveDefinitions = [
        
        MyronPrimitive(
            primitiveName: "record.get",
            representations: ["get"],
            signature: "({symbol} {record})",
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let field = try fst.unwrapSymbol(location)
                let record = try snd.unwrapRecord(location)
                return try record.get(field: field, location: location)
            }),
        
        MyronPrimitive(
            primitiveName: "record.put",
            representations: ["put"],
            signature: "({symbol} {any} {record})",
            body: { args, location in
                let (fst, value, thd) = try args.unwrap3(location)
                let field = try fst.unwrapSymbol(location)
                let record = try thd.unwrapRecord(location)
                let result = try record.put(field: field, value: value, location: location)
                return .record(result)
            }),
        
        MyronPrimitive(
            primitiveName: "record.keys-values",
            representations: ["keys-values"],
            signature: "({record})",
            body: { args, location in
                let record = try args.unwrap1(location).unwrapRecord(location)
                let result = record.keysValues().map { (k, v) in MyronValue.list([k, v]) }
                return .list(result)
            }),

        MyronPrimitive(
            primitiveName: "record.record-type",
            representations: ["record-type"],
            signature: "({record})",
            body: { args, location in
                let record = try args.unwrap1(location).unwrapRecord(location)
                return .recordType(record.type)
            }),
        
        MyronPrimitive(
            primitiveName: "record.record-isa?",
            representations: ["record-isa?"],
            signature: "({record-type} {any})",
            body: { args, location in
                let (fst, snd) = try args.unwrap2(location)
                let rectype = try fst.unwrapRecordType(location)
                guard let record = snd.asRecord else { return .boolean(false) }
                return .boolean(record.type == rectype)
            }),
        
        MyronPrimitive(
            primitiveName: "record.make-record",
            representations: ["make-record"],
            signature: "({record-type} {any}[...])",
            body: { args, location in
                let rectype = try args.unwrapFirst(location).unwrapRecordType(location)
                let values = Array(args.dropFirst())
                guard rectype.fields.count == values.count else {
                    let expected = MyronError.IntegerExpectation.exactly(rectype.fields.count + 1)
                    let reason = MyronError.Reason.unexpectedArity(values.count + 1, expected)
                    throw MyronError(reason, at: location)
                }
                
                let record = MyronRecord(type: rectype, contents: values)
                return .record(record)
            })
    
    ]
}
