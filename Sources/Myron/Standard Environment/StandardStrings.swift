import Foundation

// MARK: - Strings

struct StandardStrings {

    static func head(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        guard let head = str.first else {
            return .nothing
        }

        return .string(String(head))
    }

    static func length(args: [Value], apply: Applier, location: Range<Int>?) throws -> Value {
        let str = try args.unwrap1(location).unwrapString(location)
        return .integer(str.count)
    }




    // str-head
    // str-tail
    // str-initial
    // str-last
    // str-take
    // str-drop
    // str-length
    // empty
    // append
    // string
    // reverse
    // char
    // contains
    // trim
    // uppercase
    // lowercase





}
