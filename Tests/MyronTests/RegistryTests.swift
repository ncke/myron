import Testing
@testable import Myron

// MARK: - Registry

@Suite("Standard Registry")

struct StandardRegistryTests {

    private static let allPrimitives: [MyronPrimitive] = StandardEnvironment.modules
        .flatMap { module in module.primitiveDefinitions }

    // MARK: Registration Invariants

    private static let roster: Set<String> = [
        "!=", "%", "*", "+", "-", "/",
        "<", "<=", "==", ">", ">=", "abs",
        "acos", "add", "append", "asin", "atan", "atan2",
        "boolean?", "callable?", "cartesian-product", "ceil", "comparable?", "cons",
        "contains?", "cos", "degs-to-rads", "difference", "div", "double", "double?", "drop",
        "drop-last",
        "empty?", "eq", "explode", "finite?", "flatten", "floor", "get",
        "get-or", "gt", "gte", "has-field?", "has-key?", "head", "implode",
        "infinite?", "init", "insert", "integer", "integer?", "integers", "integers-between",
        "intersection",
        "is-disjoint?", "is-strict-subset?", "is-strict-superset?",
        "is-subset?", "is-superset?", "key-index", "keys", "keys-values", "kind",
        "last", "length", "lines", "list", "list?", "ln",
        "log", "lowercase", "lt", "lte", "make-hashmap", "make-record", "make-record-type",
        "make-set", "max", "min", "mod", "mul", "nan?", "neg",
        "negative?", "neq", "not", "nothing?", "nth", "number?",
        "positive?", "pow", "powerset", "put", "rads-to-degs", "range", "range-len",
        "record-isa?", "record-type",
        "record-type-fields", "record-type-name", "rem", "remove",
        "reverse", "round", "set", "set?", "sin", "sort", "sort-descending", "sortable?", "sqrt",
        "string", "string?", "sub", "symmetric-difference", "tail", "take", "take-last",
        "tan", "trim", "union", "uppercase", "values", "words",
        "zero?", "zip", "zip-all"
    ]

    @Test("the registered names are exactly the promised roster")
    func rosterIsUnchanged() {
        let registered = Set(Self.allPrimitives.flatMap { primitive in primitive.representations })

        let missing = Self.roster.subtracting(registered).sorted()
        let unexpected = registered.subtracting(Self.roster).sorted()

        #expect(missing.isEmpty, "no longer registered: \(missing.joined(separator: ", "))")
        #expect(unexpected.isEmpty, "newly registered: \(unexpected.joined(separator: ", "))")
    }

    @Test("every registered representation resolves")
    func representationsResolve() {
        let environment = StandardEnvironment()
        for representation in Self.roster {
            #expect(
                environment.lookup(representation) != nil,
                "\(representation) is registered but does not resolve")
        }
    }

    private static let intrinsics: Set<String> = [
        "nothing", "pi", "nan", "infinity", "map", "filter", "reduce", "all", "any"
    ]

    @Test("the intrinsic names resolve and are not also registered")
    func intrinsicsResolve() {
        let environment = StandardEnvironment()
        let registered = Set(Self.allPrimitives.flatMap { primitive in primitive.representations })

        for name in Self.intrinsics {
            #expect(environment.lookup(name) != nil, "\(name) does not resolve")
            #expect(!registered.contains(name), "\(name) is both intrinsic and registered")
        }
    }

    @Test("every primitive declares at least one representation")
    func representationsPresent() {
        for primitive in Self.allPrimitives {
            #expect(
                !primitive.representations.isEmpty,
                "\(primitive.primitiveName) registers no representation")
        }
    }

    @Test("primitive names are unique")
    func namesAreUnique() {
        var seen = Set<String>()
        for primitive in Self.allPrimitives {
            #expect(
                seen.insert(primitive.primitiveName).inserted,
                "\(primitive.primitiveName) is registered more than once")
        }
    }

    @Test("a primitive is namespaced by the module that registers it")
    func namesAreNamespaced() {
        for module in StandardEnvironment.modules {
            let namespaces = Set(
                module.primitiveDefinitions.map { primitive in
                    primitive.primitiveName.split(separator: ".").first.map(String.init) ?? ""
                })

            #expect(
                namespaces.count <= 1,
                "\(module) registers primitives across namespaces: \(namespaces.sorted())")
        }
    }

    // MARK: Resolution Invariants

    @Test("a shared representation gives every contender a signature")
    func sharedRepresentationsAreSigned() {
        var byRepresentation = [String: [MyronPrimitive]]()
        for primitive in Self.allPrimitives {
            for representation in primitive.representations {
                byRepresentation[representation, default: []].append(primitive)
            }
        }

        for (representation, contenders) in byRepresentation where contenders.count > 1 {
            for contender in contenders {
                #expect(
                    contender.signature != nil,
                    "\(contender.primitiveName) shares \(representation) but has no signature")
            }
        }
    }

}
