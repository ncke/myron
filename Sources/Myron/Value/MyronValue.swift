import Foundation

// MARK: - MyronValue

public typealias MyronPrimitive = ([MyronValue], MyronLocation?) throws -> MyronValue

public enum MyronValue {
    case boolean(Bool)
    case double(Double)
    case hashmap(MyronHashmap)
    case higherOrder(MyronHigherOrder)
    case higherProbe(MyronHigherProbe)
    case integer(Int)
    case list([MyronValue])
    case nothing
    case string(String)
    case symbol(String)
    case primitive(MyronPrimitive)
    case procedure(MyronProcedure)
    case define(String)
}

// MARK: - Atomic Type Helper

extension MyronValue {

    var isAtomicType: Bool {
        switch self {
        case .boolean, .double, .integer, .string, .symbol: return true
        default: return false
        }
    }

    static func makeValue(
        from expression: Expression,
        at location: MyronLocation?
    ) throws -> MyronValue {
        if case .atom(let atom, _) = expression { return makeValue(from: atom) }
        
        var stack = [([MyronValue], ArraySlice<Expression>)]()
        var remaining: ArraySlice<Expression> = [expression]
        var done = [MyronValue]()

        while true {
            if let next = remaining.first {
                remaining = remaining.dropFirst()
                switch next {

                case .atom(let atom, _):
                    let value = makeValue(from: atom)
                    done.append(value)

                case .list(let elements, _):
                    stack.append( (done, remaining) )
                    done = []
                    remaining = elements[0...]
                }

                continue
            }

            if let popped = stack.popLast() {
                let list = MyronValue.list(done)
                (done, remaining) = popped
                done.append(list)
                continue
            }

            guard let result = done.first else {
                let explain = "`makeValue` completed with an empty stack"
                throw MyronError(.internalError(explain), at: location)
            }

            return result
        }
    }

    static func makeValue(from atom: Atom) -> MyronValue {
        switch atom {
        case .boolean(let boolean): .boolean(boolean)
        case .double(let double): .double(double)
        case .integer(let integer): .integer(integer)
        case .string(let string): .string(string)
        case .symbol(let symbol): .symbol(symbol)
        }
    }

}

// MARK: - Description

extension MyronValue: CustomStringConvertible {

    public var description: String {
        switch self {
        case .boolean(let boolean): "\(boolean)"
        case .double(let double): "\(double)"
        case .hashmap(let hashmap): "\(hashmap)"
        case .higherOrder: "<procedure>"
        case .higherProbe: "<procedure>"
        case .integer(let integer): "\(integer)"
        case .list(let list):
            "(" + list.map(\.description).joined(separator: " ") + ")"
        case .nothing: "<nothing>"
        case .string(let string): "\"\(string)\""
        case .symbol(let symbol): "\(symbol)"
        case .primitive: "<primitive>"
        case .procedure: "<procedure>"
        case .define(let name): "<define: \(name)>"
        }
    }

}
