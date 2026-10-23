import Foundation

// MARK: - Standard Session

// Spawn is being implemented as a special form. I'm keeping this for now as a
// template. I may provide some primitives that allow an expression to introspect
// it's session or runtime.

//struct StandardSession: StandardModule {
//
//    static let primitiveDefinitions = [
//
//        MyronPrimitive(
//            primitiveName: "session.spawn",
//            representations: ["spawn"],
//            signature: "({any})",
//            body: { args, location in
//                let value = try args.unwrap1(location)
//                return .boolean(value.isModule)
//        }),
//
//    ]
//
//}
