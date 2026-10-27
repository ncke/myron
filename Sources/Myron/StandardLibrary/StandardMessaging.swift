import Foundation

// MARK: - Standard Messaging

struct StandardMessaging: StandardModule {

    static let primitiveDefinitions = [

        MyronPrimitive(
            primitiveName: "messaging.send",
            representations: ["send"],
            signature: "({process} {any})",
            contextualBody: { args, context in
                let (fst, content) = try args.unwrap2(context.location)
                let destination = try fst.unwrapProcess(context.location)
                try context.send(content, to: destination)
                return .nothing
        })

    ]

}
